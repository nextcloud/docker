import contextlib
import sys
from time import time_ns, sleep

from playwright.sync_api import Playwright, sync_playwright, expect, Error

def log_note(message: str) -> None:
    timestamp = str(time_ns())[:16]
    print(f"{timestamp} {message}")

def run(playwright: Playwright, browser_name: str) -> None:
    log_note(f"Launch browser {browser_name}")
    headless = True
    if browser_name == "firefox":
        browser = playwright.firefox.launch(headless=headless)
    else:
        browser = playwright.chromium.launch(headless=headless)

    context = browser.new_context()
    page = context.new_page()

    try:
        page.goto("http://nc/login")
        log_note("Login")
        page.get_by_label("Account name or email").fill("Crash")
        page.get_by_label("Account name or email").press("Tab")
        page.get_by_label("Password", exact=True).fill("Override")
        page.get_by_label("Password", exact=True).press("Enter")
        log_note("Wait for welcome popup")
        # Sleep to make sure the modal has time to appear before continuing navigation
        sleep(5)
        log_note("Close welcome popup")
        with contextlib.suppress(Exception):
            page.get_by_role("button", name="Close modal").click(timeout=15_000)

        log_note("Go to calendar")
        page.get_by_role("link", name="Calendar").click()

        # Second welcome screen?
        with contextlib.suppress(Exception):
            page.get_by_role("button", name="Close modal").click(timeout=15_000)

        log_note("Create event")
        event_name = "Weekly sync"
        page.get_by_role("button", name="New event").click()
        page.get_by_placeholder("Event title").fill(event_name)
        page.get_by_role("button", name="Save").click()
        log_note("Event created")
        expect(page.get_by_text(event_name, exact=True)).to_be_visible()
        page.close()
        log_note("Close browser")

    except Error as e:
        log_note(f"Exception occurred: {e.message}")
        log_note("Page content was:")
        log_note(page.content())
        raise e

    # ---------------------
    context.close()
    browser.close()


if __name__ == "__main__":
    if len(sys.argv) > 1:
        browser_name = sys.argv[1].lower()
        if browser_name not in ["chromium", "firefox"]:
            print("Invalid browser name. Please choose either 'chromium' or 'firefox'.")
            sys.exit(1)
    else:
        browser_name = "chromium"

    with sync_playwright() as playwright:
        run(playwright, browser_name)
