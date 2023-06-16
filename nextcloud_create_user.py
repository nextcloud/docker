import contextlib
from time import time_ns

from playwright.sync_api import Playwright, sync_playwright

def log_note(message: str) -> None:
    timestamp = round(time_ns() * 1000)
    print(f"{timestamp} {message}")

def create_user(playwright: Playwright, username: str, password: str) -> None:
    log_note("Launch browser")
    browser = playwright.chromium.launch(headless=True)
    context = browser.new_context()
    page = context.new_page()
    log_note("Login")
    page.goto("http://nc/")
    page.get_by_label("Account name or email").click()
    page.get_by_label("Account name or email").fill("Crash")
    page.get_by_label("Account name or email").press("Tab")
    page.get_by_label("Password", exact=True).fill("Override")
    page.get_by_label("Password", exact=True).press("Enter")
    with contextlib.suppress(Exception):
        page.get_by_role("button", name="Close modal").click(timeout=15_000)
    log_note("Create user")
    page.get_by_role("link", name="Open settings menu").click()
    page.get_by_role("link", name="Users").click()
    page.get_by_role("button", name="New user").click()
    page.get_by_placeholder("Username").click()
    page.get_by_placeholder("Username").fill(username)
    page.get_by_placeholder("Username").press("Tab")
    page.get_by_placeholder("Display name").press("Tab")
    page.get_by_placeholder("Password", exact=True).fill(password)
    page.get_by_role("button", name="Add a new user").click()
    log_note("Close browser")

    # ---------------------
    page.close()
    context.close()
    browser.close()


with sync_playwright() as playwright:
    create_user(playwright, username="docs_dude", password="docsrule!12")
