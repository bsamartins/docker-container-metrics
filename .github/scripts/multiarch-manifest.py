import json
import sys
import subprocess

if __name__ == '__main__':
    raw_metadata = sys.argv[1]
    tag = sys.argv[2]

    metadata = json.loads(raw_metadata)
    
    cmd_args = ["docker", "manifest", "create", tag]
    for image in metadata:
        image_metadata = metadata[image]
        image_name = image_metadata["image.name"]
        image_digest = image_metadata["containerimage.digest"]
        full_image = f"{image_name}@{image_digest}"
        print(f"Image: {image} - {full_image}")
        cmd_args.extend(["--amend", full_image])

    cmd_str = " ".join(cmd_args)
    print(f"cmd: {cmd_str}")
    ret_code = subprocess.call(cmd_args)
    if ret_code != 0:
        print(f"Job failed with error: {ret_code}")
        exit(ret_code)

