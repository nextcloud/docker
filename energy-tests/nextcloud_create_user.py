import sys
import contextlib
from time import time_ns, sleep
import signal

from playwright.sync_api import Playwright, sync_playwright

from helpers.helper_functions import log_note, get_random_text, login_nextcloud, close_modal, timeout_handler

def create_user(playwright: Playwright, browser_name: str, username: str, password: str, email: str, headless=False) -> None:
    log_note(f"Launch browser {browser_name}")
    if browser_name == "firefox":
        browser = playwright.firefox.launch(headless=headless)
    else:
        # this leverages new headless mode by Chromium: https://developer.chrome.com/articles/new-headless/
        # The mode is however ~40% slower: https://github.com/microsoft/playwright/issues/21216
        browser = playwright.chromium.launch(headless=headless,args=["--headless=new"])
    context = browser.new_context(ignore_https_errors=True)
    try:
        page = context.new_page()
        log_note("Login")
        login_nextcloud(page)

        log_note("Wait for welcome popup")
        #close_modal(page)

        log_note("Create user")
        page.click("button[aria-label='Settings menu']")
        page.click("#core_users")
        page.get_by_role("button", name="New Account").click()
        page.get_by_placeholder("Account name (required)", exact=True).fill(username)
        page.get_by_placeholder("Password (required)", exact=True).fill(password)
        #page.get_by_placeholder("Email", exact=True).fill(email)
        page.get_by_role("button", name="Add new account").click()
        log_note("Close browser")

        # ---------------------
        page.close()
        context.close()
        browser.close()
    except Exception as e:
        if hasattr(e, 'message'): # only Playwright error class has this member
            log_note(f"Exception occurred: {e.message}")

        # set a timeout. Since the call to page.content() is blocking we need to defer it to the OS
        signal.signal(signal.SIGALRM, timeout_handler)
        signal.alarm(20)
        #log_note(f"Page content was: {page.content()}")
        signal.alarm(0) # remove timeout signal

        raise e


with sync_playwright() as playwright:
    if len(sys.argv) > 1:
        browser_name = sys.argv[1].lower()
        if browser_name not in ["chromium", "firefox"]:
            print("Invalid browser name. Please choose either 'chromium' or 'firefox'.")
            sys.exit(1)
    else:
        browser_name = "chromium"

    create_user(playwright, browser_name, username="docs_dude", password="docsrule!12", email="docs_dude@local.host")
