import contextlib
from playwright.sync_api import Playwright, sync_playwright


def create_user(playwright: Playwright, username: str, password: str) -> None:
    browser = playwright.chromium.launch(headless=True)
    context = browser.new_context()
    page = context.new_page()
    page.goto("http://nc/")
    page.get_by_label("Account name or email").click()
    page.get_by_label("Account name or email").fill("Crash")
    page.get_by_label("Account name or email").press("Tab")
    page.get_by_label("Password", exact=True).fill("Override")
    page.get_by_label("Password", exact=True).press("Enter")
    with contextlib.suppress(Exception):
        page.get_by_role("button", name="Close modal").click(timeout=15_000)
    page.get_by_role("link", name="Open settings menu").click()
    page.get_by_role("link", name="Users").click()
    page.get_by_role("button", name="New user").click()
    page.get_by_placeholder("Username").click()
    page.get_by_placeholder("Username").fill(username)
    page.get_by_placeholder("Username").press("Tab")
    page.get_by_placeholder("Display name").press("Tab")
    page.get_by_placeholder("Password", exact=True).fill(password)
    page.get_by_role("button", name="Add a new user").click()

    # ---------------------
    page.close()
    context.close()
    browser.close()


with sync_playwright() as playwright:
    create_user(playwright, username="docs_dude", password="docsrule!12")
