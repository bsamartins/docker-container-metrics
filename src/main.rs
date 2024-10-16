use bollard::container::{ListContainersOptions, Stats, StatsOptions};
use bollard::errors::Error;
use bollard::Docker;
use futures::Stream;
use futures_util::StreamExt;
use metrics::{counter, gauge};
use metrics_exporter_prometheus::PrometheusBuilder;
use std::collections::HashMap;
use std::ops::Sub;
use std::sync::Arc;
use std::time::Duration;
use tokio::time::sleep;

#[tokio::main]
async fn main() {
    env_logger::Builder::from_env(env_logger::Env::default().default_filter_or("info")).init();

    let builder = PrometheusBuilder::new();
    builder
        .install()
        .expect("Failed to install recorder/exporter");

    log::info!("Started exporter on 0.0.0.0:9000");

    let docker = Arc::new(Docker::connect_with_local_defaults().unwrap());

    let stats_job = tokio::spawn(fetch_stats(docker));

    let _ = stats_job.await;
}

async fn fetch_stats(docker: Arc<Docker>) {
    let mut container_names = Vec::new();
    loop {
        match list_container_names(docker.clone()).await {
            Ok(containers) => {
                container_names = containers
            }
            Err(err) => {
                log::trace!("Failed to fetch container names: {}", err);
            }
        }

        let mut stats_stream = containers_stats(docker.clone(), &container_names);

        while let Some(stats_result) = stats_stream.next().await {
            match stats_result {
                Ok(ref stats) => { record_stats(stats); }
                Err(err) => { log::error!("{:?}", err); }
            }
        }
        sleep(Duration::from_secs(1)).await;
    }
}

fn record_stats(stats: &Stats) {
    let container_name = normalize_container_name(stats.name.as_str());
    let container_name_label = ("name", container_name.clone());

    let cpu_labels = [container_name_label.clone()];

    if let Some(percentage) = calculate_percent_unix(stats) {
        gauge!("container_cpu_usage", &cpu_labels).set(percentage);
    }

    if let Some(ref networks) = stats.networks {
        networks.iter().for_each(|(network, net_stats)| {
            let network_labels = &[container_name_label.clone(), ("network", network.to_string())];
            counter!("container_network_rx_bytes", network_labels).absolute(net_stats.rx_bytes);
            counter!("container_network_tx_bytes", network_labels).absolute(net_stats.tx_bytes);
            counter!("container_network_rx_packets", network_labels).absolute(net_stats.rx_packets);
            counter!("container_network_tx_packets", network_labels).absolute(net_stats.tx_packets);
        })
    }
}

fn containers_stats(docker: Arc<Docker>, container_names: &Vec<String>) -> impl Stream<Item=Result<Stats, Error>> + Sized {
    let stats_options = StatsOptions {
        stream: false,
        ..Default::default()
    };

    log::trace!("fetching stats for {:?}", container_names);
    let streams = container_names.iter().map(|container_name| {
        docker.stats(container_name, Some(stats_options))
    }).collect::<Vec<_>>();

    futures::stream::select_all(streams)
}

async fn list_container_names(docker: Arc<Docker>) -> Result<Vec<String>, Error> {
    let mut filters = HashMap::new();
    filters.insert("status", vec!["running"]);

    let list_container_options = Some(ListContainersOptions {
        all: true,
        filters,
        ..Default::default()
    });
    docker.list_containers(list_container_options)
        .await
        .map(|containers|
            containers.iter()
                .map(|c| normalize_container_name(c.clone().names.unwrap().first().unwrap()))
                .collect::<Vec<_>>()
        )
}

fn _calculate_percent_windows(stats: &Stats) -> Option<f64> {
    let read = chrono::DateTime::parse_from_rfc3339(stats.read.as_str());
    let pre_read = chrono::DateTime::parse_from_rfc3339(stats.preread.as_str());

    match (read, pre_read) {
        (Ok(read), Ok(pre_read)) => {
            read.time().sub(pre_read.time())
                .num_nanoseconds()
                .map(|n| n / 100)
                .map(|n| n * stats.num_procs as i64)
        }
        _ => None
    }.filter(|poss_intervals| *poss_intervals > 0)
        .map(|poss_intervals| {
            let intervals_used = stats.cpu_stats.cpu_usage.total_usage - stats.precpu_stats.cpu_usage.total_usage;
            intervals_used as f64 / poss_intervals as f64 * 100.0
        })
}

fn calculate_percent_unix(stats: &Stats) -> Option<f64> {
    let previous_cpu = stats.precpu_stats.cpu_usage.total_usage;
    let previous_system = stats.precpu_stats.system_cpu_usage;
    let per_cpu_usage_len = stats.clone().cpu_stats.cpu_usage.percpu_usage
        .map(|vec| vec.len() as u64)
        .unwrap_or(0);

    match (previous_system, stats.cpu_stats.system_cpu_usage) {
        (Some(previous_system), Some(system_cpu_usage)) => {
            let cpu_delta = stats.cpu_stats.cpu_usage.total_usage - previous_cpu;
            let system_delta = system_cpu_usage - previous_system;
            let mut online_cpus = stats.cpu_stats.online_cpus.unwrap_or(0);

            if online_cpus == 0 {
                online_cpus = per_cpu_usage_len
            }
            if system_delta > 0 && cpu_delta > 0 {
                Some(((cpu_delta as f64 / system_delta as f64) * online_cpus as f64) * 100.0f64)
            } else {
                None
            }
        }
        _ => None
    }
}

fn normalize_container_name(name: &str) -> String {
    name.replace("/", "")
}
