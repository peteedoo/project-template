from __future__ import annotations

from dataclasses import dataclass, field
from pathlib import Path
from typing import Any

import yaml

DEFAULT_CONFIG_PATH = Path("/etc/minifw/firewall.yaml")
EXAMPLE_CONFIG_PATH = Path("/etc/minifw/firewall.example.yaml")


@dataclass
class InterfaceConfig:
    wan: str = "enp0s20u1"
    lan: str = "enp2s0f0"


@dataclass
class LanConfig:
    subnet: str = "192.168.10.0/24"
    gateway: str = "192.168.10.1"
    dhcp_start: str = "192.168.10.100"
    dhcp_end: str = "192.168.10.250"
    dns_servers: list[str] = field(default_factory=lambda: ["1.1.1.1", "1.0.0.1"])


@dataclass
class PortForward:
    name: str
    proto: str
    wan_port: int
    lan_ip: str
    lan_port: int


@dataclass
class FirewallConfig:
    hostname: str = "mac-mini-fw"
    interfaces: InterfaceConfig = field(default_factory=InterfaceConfig)
    lan: LanConfig = field(default_factory=LanConfig)
    allow_icmp: bool = True
    block_countries: list[str] = field(default_factory=list)
    blocked_ips: list[str] = field(default_factory=list)
    allowed_wan_ports: list[dict[str, Any]] = field(default_factory=list)
    port_forwards: list[PortForward] = field(default_factory=list)
    management_cidr: str = "192.168.10.0/24"

    @classmethod
    def from_dict(cls, data: dict[str, Any]) -> FirewallConfig:
        interfaces = InterfaceConfig(**data.get("interfaces", {}))
        lan = LanConfig(**data.get("lan", {}))
        port_forwards = [
            PortForward(**entry) for entry in data.get("port_forwards", [])
        ]
        return cls(
            hostname=data.get("hostname", "mac-mini-fw"),
            interfaces=interfaces,
            lan=lan,
            allow_icmp=data.get("allow_icmp", True),
            block_countries=data.get("block_countries", []),
            blocked_ips=data.get("blocked_ips", []),
            allowed_wan_ports=data.get("allowed_wan_ports", []),
            port_forwards=port_forwards,
            management_cidr=data.get("management_cidr", lan.subnet),
        )

    def to_dict(self) -> dict[str, Any]:
        return {
            "hostname": self.hostname,
            "interfaces": {
                "wan": self.interfaces.wan,
                "lan": self.interfaces.lan,
            },
            "lan": {
                "subnet": self.lan.subnet,
                "gateway": self.lan.gateway,
                "dhcp_start": self.lan.dhcp_start,
                "dhcp_end": self.lan.dhcp_end,
                "dns_servers": self.lan.dns_servers,
            },
            "allow_icmp": self.allow_icmp,
            "block_countries": self.block_countries,
            "blocked_ips": self.blocked_ips,
            "allowed_wan_ports": self.allowed_wan_ports,
            "port_forwards": [
                {
                    "name": pf.name,
                    "proto": pf.proto,
                    "wan_port": pf.wan_port,
                    "lan_ip": pf.lan_ip,
                    "lan_port": pf.lan_port,
                }
                for pf in self.port_forwards
            ],
            "management_cidr": self.management_cidr,
        }


def load_config(path: Path | None = None) -> FirewallConfig:
    config_path = path or DEFAULT_CONFIG_PATH
    if not config_path.exists():
        raise FileNotFoundError(
            f"Config not found at {config_path}. Run `minifw init` first."
        )
    with config_path.open() as handle:
        data = yaml.safe_load(handle) or {}
    return FirewallConfig.from_dict(data)


def save_config(config: FirewallConfig, path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w") as handle:
        yaml.safe_dump(config.to_dict(), handle, default_flow_style=False, sort_keys=False)
