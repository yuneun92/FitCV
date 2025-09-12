import httpx
from FitCV.services.collectors import (
    GreenhouseCollector,
    LeverCollector,
    SaraminCollector,
    WorkNetCollector,
)


class FakeResponse:
    def __init__(self, json_data=None, text="", status_code: int = 200):
        self._json_data = json_data
        self.text = text
        self.status_code = status_code

    def raise_for_status(self) -> None:
        if self.status_code >= 400:
            raise httpx.HTTPStatusError("error", request=None, response=None)

    def json(self):
        if self._json_data is None:
            raise ValueError("No JSON data")
        return self._json_data


class FakeClient:
    def __init__(self, response: FakeResponse):
        self._response = response
        self.url_captured = None
        self.params_captured = None
        self.closed = False

    def __enter__(self):
        return self

    def __exit__(self, exc_type, exc, tb):
        self.closed = True
        return False

    def get(self, url: str, params=None):
        self.url_captured = url
        self.params_captured = params or {}
        return self._response


def test_saramin_collect(monkeypatch):
    response = FakeResponse(json_data={"jobs": []})

    def fake_client_factory(*args, **kwargs):
        return FakeClient(response)

    monkeypatch.setattr(httpx, "Client", fake_client_factory)

    collector = SaraminCollector(access_key="dummy")
    result = collector.collect(keyword="python")

    assert isinstance(result, list)
    assert result and result[0]["source"] == "saramin"


def test_worknet_collect(monkeypatch):
    response = FakeResponse(json_data={"wanted": []})

    def fake_client_factory(*args, **kwargs):
        return FakeClient(response)

    monkeypatch.setattr(httpx, "Client", fake_client_factory)

    collector = WorkNetCollector(service_key="dummy")
    result = collector.collect(region="seoul")

    assert isinstance(result, list)
    assert result and result[0]["source"] == "worknet"


def test_greenhouse_collect(monkeypatch):
    response = FakeResponse(json_data={"jobs": [{"id": 1, "title": "SWE"}]})

    def fake_client_factory(*args, **kwargs):
        return FakeClient(response)

    monkeypatch.setattr(httpx, "Client", fake_client_factory)

    collector = GreenhouseCollector(company_slug="exampleco")
    result = collector.collect()

    assert isinstance(result, list)
    assert result and result[0]["source"] == "greenhouse"
    assert result[0]["company"] == "exampleco"
    assert isinstance(result[0]["raw"], dict)


def test_lever_collect(monkeypatch):
    response = FakeResponse(json_data=[{"id": 1}])

    def fake_client_factory(*args, **kwargs):
        return FakeClient(response)

    monkeypatch.setattr(httpx, "Client", fake_client_factory)

    collector = LeverCollector(company_slug="exampleco")
    result = collector.collect()

    assert isinstance(result, list)
    assert result and result[0]["source"] == "lever"
    assert result[0]["company"] == "exampleco" 