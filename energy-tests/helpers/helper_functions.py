import contextlib
import random
import string
from time import time_ns, sleep
from playwright.sync_api import TimeoutError


def login_nextcloud(page, username='Crash', password='Override', domain='https://ncs'):
    page.goto(f"{domain}/login")
    page.locator('#user').fill(username)
    page.locator('#password').fill(password)
    page.locator('#password').press("Enter")


def get_random_text() -> str:
    size_in_bytes = 10
    characters = string.ascii_letters + string.digits
    return ''.join(random.choice(characters) for _ in range(size_in_bytes))

def log_note(message: str) -> None:
    timestamp = str(time_ns())[:16]
    print(f"{timestamp} {message}")


def close_modal(page) -> None:
    with contextlib.suppress(TimeoutError):
        sleep(5) # Sleep to make sure the modal has time to appear before continuing navigation
        page.locator('#firstrunwizard .modal-container__content button[aria-label=Close]').click(timeout=15_000)


def timeout_handler(signum, frame):
    raise TimeoutError("Page.content() timed out")
