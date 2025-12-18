
#!/usr/bin/env python3
import json, sys

if len(sys.argv) < 3:
    print("Usage: make_inventory.py <terraform-outputs.json> <inventory.ini>")
    sys.exit(1)

with open(sys.argv[1]) as f:
    data = json.load(f)

def val(k):
    return data[k]["value"]

web_pub = val("web_public_ips")
db_priv = val("db_private_ips")

with open(sys.argv[2], "w") as f:
    f.write("[web]\n")
    for ip in web_pub:
        f.write(f"{ip}\n")

    f.write("\n[db]\n")
    for ip in db_priv:
        f.write(f"{ip}\n")

    # Use first web host as bastion for DB
    if web_pub:
        bastion = web_pub[0]
        f.write("\n[db:vars]\n")
        f.write(f"ansible_ssh_common_args=-o ProxyJump=ec2-user@{bastion}\n")

print("Inventory written to", sys.argv[2])

