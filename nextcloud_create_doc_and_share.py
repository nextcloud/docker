from time import time_ns

from playwright.sync_api import Playwright, sync_playwright

def log_note(message: str) -> None:
    timestamp = round(time_ns() * 1000)
    print(f"{timestamp} {message}")

def run(playwright: Playwright) -> None:
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
    log_note("Create new text file")
    page.get_by_role("link", name="Files").click()
    page.get_by_role("link", name="New file/folder menu").click()
    page.get_by_role("link", name="New text file").click()
    page.locator("#view9-input-file").fill("colab_meeting.md")
    page.locator("#view9-input-file").press("Enter")
    page.get_by_role("button", name="Create a new file with the selected template").click()
    page.get_by_role("button", name="Close modal").click()
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


with sync_playwright() as playwright:
    run(playwright)
