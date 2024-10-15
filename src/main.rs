use bollard::container::{ListContainersOptions, Stats, StatsOptions};
use bollard::errors::Error;
use bollard::models::ContainerSummary;
use bollard::Docker;
use futures_util::stream::StreamExt;
use futures_util::Stream;
use metrics::gauge;
use metrics_exporter_prometheus::PrometheusBuilder;
use std::collections::HashMap;

#[tokio::main]
async fn main() {
    let builder = PrometheusBuilder::new();
    builder
        .install()
        .expect("failed to install recorder/exporter");

    let docker = Docker::connect_with_unix_defaults().unwrap();

    let containers = list_containers(&docker)
        .await;

    let container_names = containers.iter()
        .map(|c| c.clone().names.unwrap().first().unwrap().to_string().replace("/", ""))
        .collect();

    let mut stats_stream = container_stats(docker, container_names);

    while let Some(stats_result) = stats_stream.next().await {
        match stats_result {
            Ok(stats) => {
                let container_name = stats.name.replace("/", "");
                let container_name_label = ("name", container_name.clone());
                match stats.networks {
                    Some(networks) => {
                        networks.iter().for_each(|(network, net_stats)| {
                            let network_labels = &[container_name_label.clone(), ("network", network.to_string())];
                            gauge!("container_network_rx_bytes", network_labels).set(net_stats.rx_bytes as f64);
                            gauge!("container_network_tx_bytes", network_labels).set(net_stats.tx_bytes as f64);
                            gauge!("container_network_rx_packets", network_labels).set(net_stats.rx_packets as f64);
                            gauge!("container_network_tx_packets", network_labels).set(net_stats.tx_packets as f64);
                        })
                    }
                    None => {}
                }
            }
            Err(err) => {
                println!("{:?}", err);
            }
        }
    }
}

fn container_stats(docker: Docker, container_names: Vec<String>) -> impl Stream<Item=Result<Stats, Error>> + Sized {
    let stats_options = StatsOptions {
        stream: true,
        ..Default::default()
    };

    let streams = container_names.iter().map(|container_name| {
        docker.stats(container_name, Some(stats_options))
    }).collect::<Vec<_>>();

    futures::stream::select_all(streams)
}

async fn list_containers(docker: &Docker) -> Vec<ContainerSummary> {
    let mut filters = HashMap::new();
    filters.insert("status", vec!["running"]);

    let list_container_options = Some(ListContainersOptions {
        all: true,
        filters,
        ..Default::default()
    });

    docker.list_containers(list_container_options).await
        .expect("list containers")
}
