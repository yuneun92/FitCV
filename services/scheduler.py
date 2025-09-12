from __future__ import annotations

import threading
import time
from typing import Callable, Optional


class PeriodicJobRunner:
    """Run a given job function periodically in a background thread.

    The runner supports start/stop and will continue executing even if the job raises,
    logging the exception and proceeding on the next interval.
    """

    def __init__(
        self,
        name: str,
        interval_seconds: float,
        job_function: Callable[[], None],
        *,
        on_error: Optional[Callable[[BaseException], None]] = None,
        on_info: Optional[Callable[[str], None]] = None,
    ) -> None:
        self.name = name
        self.interval_seconds = interval_seconds
        self.job_function = job_function
        self.on_error = on_error
        self.on_info = on_info
        self._thread: Optional[threading.Thread] = None
        self._stop_event = threading.Event()

    def start(self) -> None:
        if self._thread and self._thread.is_alive():
            return

        def _run_loop() -> None:
            if self.on_info:
                self.on_info(f"[{self.name}] runner started; interval={self.interval_seconds}s")
            try:
                while not self._stop_event.is_set():
                    start_ts = time.time()
                    try:
                        self.job_function()
                    except BaseException as exc:  # noqa: BLE001
                        if self.on_error:
                            self.on_error(exc)
                    elapsed = time.time() - start_ts
                    remaining = max(0.0, self.interval_seconds - elapsed)
                    if remaining > 0:
                        self._stop_event.wait(remaining)
            finally:
                if self.on_info:
                    self.on_info(f"[{self.name}] runner stopped")

        self._stop_event.clear()
        self._thread = threading.Thread(target=_run_loop, name=self.name, daemon=True)
        self._thread.start()

    def stop(self, timeout_seconds: Optional[float] = 5.0) -> None:
        self._stop_event.set()
        if self._thread and self._thread.is_alive():
            self._thread.join(timeout_seconds)
            self._thread = None 