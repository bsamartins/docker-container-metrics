group "test" {
    targets = ["linux-amd64", "linux-arm64"]
}

target "base" {
    dockerfile = "Dockerfile"
    context = "."
}

target "linux-amd64" {
    inherits = ["base"]
    platforms = ["linux/amd64"]
    args {
        ARCH = "amd64"
    }
    tags = ["bsamartins/docker-container-metrics:amd64"]
}

target "linux-arm64" {
    inherits = ["base"]
    platforms = ["linux/arm64"]
    args {
        ARCH = "arm64"
    }
    tags = ["bsamartins/docker-container-metrics:arm64"]
}
