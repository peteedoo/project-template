from minifw.config import FirewallConfig
from minifw.rules import render_nftables


def test_render_includes_interfaces():
    config = FirewallConfig()
    config.interfaces.wan = "eth0"
    config.interfaces.lan = "eth1"
    rules = render_nftables(config)
    assert 'iif "eth0"' in rules
    assert 'iif "eth1"' in rules
    assert "192.168.10.0/24" in rules
    assert "masquerade" in rules


def test_render_port_forward():
    config = FirewallConfig()
    config.interfaces.wan = "wan0"
    from minifw.config import PortForward

    config.port_forwards.append(
        PortForward(
            name="web",
            proto="tcp",
            wan_port=443,
            lan_ip="192.168.10.50",
            lan_port=443,
        )
    )
    rules = render_nftables(config)
    assert "dnat to 192.168.10.50:443" in rules
    assert "tcp dport 443" in rules
