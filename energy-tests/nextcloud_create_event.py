import contextlib
import sys
from time import time_ns, sleep
import signal

from playwright.sync_api import Playwright, sync_playwright, expect, TimeoutError

def timeout_handler(signum, frame):
    raise TimeoutError("Page.content() timed out")

def log_note(message: str) -> None:
    timestamp = str(time_ns())[:16]
    print(f"{timestamp} {message}")

def run(playwright: Playwright, browser_name: str) -> None:
    log_note(f"Launch browser {browser_name}")
    if browser_name == "firefox":
        browser = playwright.firefox.launch(headless=True)
    else:
        # this leverages new headless mode by Chromium: https://developer.chrome.com/articles/new-headless/
        # The mode is however ~40% slower: https://github.com/microsoft/playwright/issues/21216
        browser = playwright.chromium.launch(headless=False,args=["--headless=new"])
    context = browser.new_context()
    page = context.new_page()

    try:
        page.goto("http://nc/login")
        log_note("Login")
        page.get_by_label("Login with username or email").fill("Crash")
        page.get_by_label("Login with username or email").press("Tab")
        page.get_by_label("Password", exact=True).fill("Override")
        page.get_by_label("Password", exact=True).press("Enter")
        log_note("Wait for welcome popup")
        # Sleep to make sure the modal has time to appear before continuing navigation
        sleep(5)
        log_note("Close welcome popup")
        with contextlib.suppress(TimeoutError):
            page.locator('#firstrunwizard .modal-container__content button[aria-label=Close]').click(timeout=15_000)

        log_note("Go to calendar")
        page.get_by_role("link", name="Calendar").click()

        # Second welcome screen?
        with contextlib.suppress(TimeoutError):
            page.locator('#firstrunwizard .modal-container__content button[aria-label=Close]').click(timeout=15_000)

        log_note("Create event")
        event_name = "Weekly sync"
        page.get_by_role("button", name="New event").click()
        page.get_by_placeholder("Event title").fill(event_name)
        page.get_by_role("button", name="Save").click()
        log_note("Event created")
        expect(page.get_by_text(event_name, exact=True)).to_be_visible()
        page.close()
        log_note("Close browser")

    except Exception as e:
        if hasattr(e, 'message'): # only Playwright error class has this member
            log_note(f"Exception occurred: {e.message}")

        # set a timeout. Since the call to page.content() is blocking we need to defer it to the OS
        signal.signal(signal.SIGALRM, timeout_handler)
        signal.alarm(5)
        log_note(f"Page content was: {page.content()}")
        signal.alarm(0) # remove timeout signal

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
