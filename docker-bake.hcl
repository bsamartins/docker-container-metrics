target "local" {
    dockerfile = "Docker.local.dockerfile"
    tags = ["docker-container-metrics:latest"]
    output = ["type=docker"]
}

group "linux" {
  targets = ["linux-amd64", "linux-arm64"]
}

target "linux-amd64" {
    dockerfile = "Docker.linux.dockerfile"
    platforms = ["linux/amd64"]
    args = {
        BINARY = "target/x86_64-unknown-linux-gnu/release/docker-container-metrics"
    }
}

target "linux-arm64" {
    dockerfile = "Docker.linux.dockerfile"
    platforms = ["linux/arm64"]
    args = {
        BINARY = "target/aarch64-unknown-linux-gnu/release/docker-container-metrics"
    }
}