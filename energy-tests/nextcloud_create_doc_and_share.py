import contextlib
import sys
from time import sleep, time_ns

from playwright.sync_api import Playwright, sync_playwright, Error

def log_note(message: str) -> None:
    timestamp = str(time_ns())[:16]
    print(f"{timestamp} {message}")

def run(playwright: Playwright, browser_name: str) -> None:
    log_note(f"Launch browser {browser_name}")
    if browser_name == "firefox":
        browser_type = playwright.firefox
    else:
        browser_type = playwright.chromium
    browser = browser_type.launch(headless=True)
    context = browser.new_context()
    page = context.new_page()
    try:
        log_note("Login")
        page.goto("http://nc/")
        page.get_by_label("Account name or email").click()
        page.get_by_label("Account name or email").fill("Crash")
        page.get_by_label("Account name or email").press("Tab")
        page.get_by_label("Password", exact=True).fill("Override")
        page.get_by_label("Password", exact=True).press("Enter")
        log_note("Create new text file")
        page.get_by_role("link", name="Files").click()
        page.get_by_role("link", name="New file/folder menu").click()
        page.get_by_role("link", name="New text file").click()
        page.locator("#view7-input-file").fill("colab_meeting.md")
        page.locator("#view7-input-file").press("Enter")
        page.get_by_role("button", name="Create a new file with the selected template").click()
        sleep(5)
        with contextlib.suppress(Exception):
            page.get_by_role("button", name="Close modal").click(timeout=15_000)
        page.keyboard.press("Escape")
        log_note("Share file with other user")
        page.get_by_role("link", name="colab_meeting .md").get_by_role("link", name="Share").click()
        page.get_by_placeholder("Name, email, or Federated Cloud ID …").click()
        page.get_by_placeholder("Name, email, or Federated Cloud ID …").fill("docs")
        page.get_by_text("docs_dude").first.click()
        log_note("Close browser")
        page.close()

        # ---------------------
        context.close()
        browser.close()
    except Error as e:
        log_note(f"Exception occurred: {e.message}")
        log_note(f"Page content was: {page.content()}")
        raise e


with sync_playwright() as playwright:
    if len(sys.argv) > 1:
        browser_name = sys.argv[1].lower()
        if browser_name not in ["chromium", "firefox"]:
            print("Invalid browser name. Please choose either 'chromium' or 'firefox'.")
            sys.exit(1)
    else:
        browser_name = "chromium"

    run(playwright, browser_name)
