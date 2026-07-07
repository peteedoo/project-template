from __future__ import annotations

import argparse
import shutil
import subprocess
import sys
from pathlib import Path

from minifw import __version__
from minifw.config import (
    DEFAULT_CONFIG_PATH,
    FirewallConfig,
    load_config,
    save_config,
)
from minifw.rules import NFTABLES_PATH, write_rules

DNSMASQ_PATH = Path("/etc/dnsmasq.d/minifw.conf")
SYSCTL_PATH = Path("/etc/sysctl.d/99-minifw.conf")


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        prog="minifw",
        description="Firewall manager for a Mac Mini home router",
    )
    parser.add_argument("--version", action="version", version=f"minifw {__version__}")
    parser.add_argument(
        "--config",
        type=Path,
        default=DEFAULT_CONFIG_PATH,
        help="Path to firewall YAML config",
    )

    subparsers = parser.add_subparsers(dest="command", required=True)

    init_parser = subparsers.add_parser("init", help="Create a starter config")
    init_parser.add_argument("--wan", help="WAN interface name")
    init_parser.add_argument("--lan", help="LAN interface name")
    init_parser.add_argument("--force", action="store_true", help="Overwrite existing config")

    subparsers.add_parser("show", help="Print the active configuration")
    subparsers.add_parser("render", help="Print generated nftables rules")
    subparsers.add_parser("apply", help="Write configs and reload services")
    subparsers.add_parser("status", help="Show firewall and interface status")

    block_parser = subparsers.add_parser("block", help="Block an IP address")
    block_parser.add_argument("ip", help="IPv4 address to block")

    allow_parser = subparsers.add_parser("allow-wan", help="Allow inbound WAN port")
    allow_parser.add_argument("proto", choices=["tcp", "udp"])
    allow_parser.add_argument("port", type=int)
    allow_parser.add_argument("--source", help="Restrict to source CIDR")

    args = parser.parse_args(argv)

    try:
        if args.command == "init":
            return cmd_init(args)
        if args.command == "show":
            return cmd_show(args)
        if args.command == "render":
            return cmd_render(args)
        if args.command == "apply":
            return cmd_apply(args)
        if args.command == "status":
            return cmd_status(args)
        if args.command == "block":
            return cmd_block(args)
        if args.command == "allow-wan":
            return cmd_allow_wan(args)
    except FileNotFoundError as exc:
        print(exc, file=sys.stderr)
        return 1
    except subprocess.CalledProcessError as exc:
        print(f"Command failed: {exc}", file=sys.stderr)
        return exc.returncode

    parser.print_help()
    return 1


def cmd_init(args: argparse.Namespace) -> int:
    if args.config.exists() and not args.force:
        print(f"Config already exists at {args.config}. Use --force to overwrite.")
        return 1

    config = FirewallConfig()
    if args.wan:
        config.interfaces.wan = args.wan
    if args.lan:
        config.interfaces.lan = args.lan
    else:
        detected = detect_interfaces()
        if detected:
            config.interfaces.wan, config.interfaces.lan = detected

    save_config(config, args.config)
    print(f"Created config at {args.config}")
    print(f"  WAN: {config.interfaces.wan}")
    print(f"  LAN: {config.interfaces.lan}")
    print(f"  LAN subnet: {config.lan.subnet}")
    print("Edit the config, then run: sudo minifw apply")
    return 0


def cmd_show(args: argparse.Namespace) -> int:
    import yaml

    config = load_config(args.config)
    print(yaml.safe_dump(config.to_dict(), default_flow_style=False, sort_keys=False))
    return 0


def cmd_render(args: argparse.Namespace) -> int:
    from minifw.rules import render_nftables

    config = load_config(args.config)
    print(render_nftables(config))
    return 0


def cmd_apply(args: argparse.Namespace) -> int:
    config = load_config(args.config)
    write_rules(config, NFTABLES_PATH)
    DNSMASQ_PATH.parent.mkdir(parents=True, exist_ok=True)
    DNSMASQ_PATH.write_text(render_dnsmasq(config))
    SYSCTL_PATH.write_text(render_sysctl())
    run(["nft", "-f", str(NFTABLES_PATH)])
    restart_if_active("dnsmasq")
    run(["sysctl", "--system"])
    print("Firewall rules applied.")
    return 0


def cmd_status(args: argparse.Namespace) -> int:
    config = load_config(args.config)
    print(f"Hostname: {config.hostname}")
    print(f"WAN: {config.interfaces.wan}")
    print(f"LAN: {config.interfaces.lan}")
    print(f"LAN subnet: {config.lan.subnet}")
    print()
    run(["ip", "-br", "addr"], check=False)
    print()
    run(["nft", "list", "ruleset"], check=False)
    return 0


def cmd_block(args: argparse.Namespace) -> int:
    config = load_config(args.config)
    if args.ip not in config.blocked_ips:
        config.blocked_ips.append(args.ip)
        save_config(config, args.config)
    return cmd_apply(args)


def cmd_allow_wan(args: argparse.Namespace) -> int:
    config = load_config(args.config)
    entry = {"proto": args.proto, "port": args.port}
    if args.source:
        entry["source"] = args.source
    config.allowed_wan_ports.append(entry)
    save_config(config, args.config)
    return cmd_apply(args)


def detect_interfaces() -> tuple[str, str] | None:
    try:
        output = run(["ip", "-o", "link", "show"], capture=True, text=True)
    except (FileNotFoundError, subprocess.CalledProcessError):
        return None

    names = []
    for line in output.stdout.splitlines():
        parts = line.split(": ", 2)
        if len(parts) < 2:
            continue
        name = parts[1].split("@", 1)[0]
        if name == "lo" or name.startswith(("docker", "veth", "br-")):
            continue
        names.append(name)

    if len(names) >= 2:
        # Prefer USB-attached NICs as WAN on Mac Minis.
        usb = [n for n in names if "usb" in n.lower() or n.startswith("enx")]
        wired = [n for n in names if n not in usb]
        if usb and wired:
            return usb[0], wired[0]
        return names[0], names[1]
    return None


def render_dnsmasq(config: FirewallConfig) -> str:
    dns = ", ".join(config.lan.dns_servers)
    return f"""# Generated by minifw
interface={config.interfaces.lan}
bind-interfaces
dhcp-range={config.lan.dhcp_start},{config.lan.dhcp_end},12h
dhcp-option=option:router,{config.lan.gateway}
dhcp-option=option:dns-server,{dns}
domain-needed
bogus-priv
no-resolv
server={config.lan.dns_servers[0]}
server={config.lan.dns_servers[1] if len(config.lan.dns_servers) > 1 else config.lan.dns_servers[0]}
"""


def render_sysctl() -> str:
    return """# Generated by minifw
net.ipv4.ip_forward=1
net.ipv6.conf.all.forwarding=0
net.ipv4.conf.all.rp_filter=1
net.ipv4.conf.default.rp_filter=1
net.ipv4.icmp_echo_ignore_broadcasts=1
net.ipv4.conf.all.accept_redirects=0
net.ipv4.conf.default.accept_redirects=0
net.ipv4.conf.all.send_redirects=0
net.ipv4.conf.default.send_redirects=0
"""


def run(cmd: list[str], **kwargs) -> subprocess.CompletedProcess:
    return subprocess.run(cmd, check=True, **kwargs)


def restart_if_active(service: str) -> None:
    if shutil.which("systemctl") is None:
        return
    result = subprocess.run(
        ["systemctl", "is-active", "--quiet", service],
        check=False,
    )
    if result.returncode == 0:
        run(["systemctl", "restart", service])


if __name__ == "__main__":
    raise SystemExit(main())
