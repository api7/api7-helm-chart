"""Render real Helm manifests and check Dashboard listener consistency.

Run with Python 3, PyYAML and Helm installed:
    python3 tests/dashboard_listener_ports.py
"""

import os
from pathlib import Path
import subprocess
import unittest

import yaml


CHART = os.environ.get(
    "API7_TEST_CHART", str(Path(__file__).resolve().parents[1] / "charts/api7")
)


def render(**values):
    command = ["helm", "template", "test", CHART]
    for key, value in {
        "prometheus.builtin": False,
        "postgresql.builtin": False,
        "jaeger.builtin": False,
        **values,
    }.items():
        encoded = str(value).lower() if isinstance(value, bool) else str(value)
        command.extend(["--set", f"{key}={encoded}"])
    return subprocess.run(command, capture_output=True, text=True, check=False)


class DashboardListenerPorts(unittest.TestCase):
    def check_render(self, http, https, service_type="ClusterIP", custom=False):
        values = {"dashboard_service.type": service_type}
        if http is not None:
            values["dashboard_configuration.server.listen.disable"] = not http
            values["dashboard_configuration.server.tls.disable"] = not https
        expected = (["http"] if http else []) + (["https"] if https else [])
        service_ports = {"http": 7080, "https": 7443}
        container_ports = dict(service_ports)
        if custom:
            service_ports = {"http": 8080, "https": 8443}
            container_ports = {"http": 9080, "https": 9443}
            values.update({
                "dashboard_service.port": 8080,
                "dashboard_service.tlsPort": 8443,
                "dashboard_configuration.server.listen.port": 9080,
                "dashboard_configuration.server.tls.port": 9443,
            })
        if service_type == "NodePort":
            values.update({
                "dashboard_service.nodePort": 30080,
                "dashboard_service.tlsNodePort": 30443,
            })
        result = render(**values)
        self.assertEqual(result.returncode, 0, result.stderr)
        resources = {
            item["kind"]: item for item in yaml.safe_load_all(result.stdout)
            if item and item["metadata"]["name"] == "test-api7ee3-dashboard"
        }
        ports = resources["Service"]["spec"]["ports"]
        self.assertEqual(resources["Service"]["spec"]["type"], service_type)
        self.assertEqual([port["name"] for port in ports], expected)
        for port in ports:
            name = port["name"]
            self.assertEqual(port["targetPort"], name)
            self.assertEqual(port["port"], service_ports[name])
            if service_type == "NodePort":
                self.assertEqual(port["nodePort"], {"http": 30080, "https": 30443}[name])
            else:
                self.assertNotIn("nodePort", port)
        container = resources["Deployment"]["spec"]["template"]["spec"]["containers"][0]
        self.assertEqual(
            {port["name"]: port["containerPort"] for port in container["ports"]},
            {name: container_ports[name] for name in expected},
        )
        for probe in ("livenessProbe", "readinessProbe"):
            self.assertEqual(container[probe]["httpGet"]["port"], expected[0])
            self.assertEqual(container[probe]["httpGet"]["scheme"], expected[0].upper())

    def test_default_is_https_only(self):
        self.check_render(None, True)

    def test_listener_and_service_combinations(self):
        for service_type in ("ClusterIP", "NodePort", "LoadBalancer"):
            for http, https in ((True, False), (False, True), (True, True)):
                with self.subTest(service_type=service_type, http=http, https=https):
                    self.check_render(http, https, service_type, custom=True)

    def test_both_listeners_disabled(self):
        result = render(**{
            "dashboard_configuration.server.listen.disable": True,
            "dashboard_configuration.server.tls.disable": True,
        })
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("Dashboard requires at least one enabled listener", result.stderr)


if __name__ == "__main__":
    unittest.main(verbosity=2)
