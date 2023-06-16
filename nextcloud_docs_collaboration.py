import random
import string
from time import time_ns, sleep

from playwright.sync_api import Playwright, sync_playwright, expect


def get_random_text() -> str:
    size_in_bytes = 1024
    characters = string.ascii_letters + string.digits
    return ''.join(random.choice(characters) for _ in range(size_in_bytes))

def log_note(message: str) -> None:
    timestamp = str(time_ns())[:16]
    print(f"{timestamp} {message}")

def collaborate(playwright: Playwright) -> None:
    log_note("Launching browsers")
    browser = playwright.chromium.launch(headless=True)
    context = browser.new_context()
    admin_user = context.new_page()

    browser_two = playwright.chromium.launch(headless=True)
    context_two = browser_two.new_context()
    docs_user = context_two.new_page()

    # Login and open the file for both users
    log_note("Logging in with users")
    login(admin_user, "Crash", "Override")
    login(docs_user, "docs_dude", "docsrule!12")
    log_note("Opening document with both users")
    docs_user.get_by_role("button", name="Close modal").click(timeout=15_000)
    admin_user.get_by_role("link", name="Files").click()
    docs_user.get_by_role("link", name="Files").click()
    admin_user.get_by_role("link", name="Shares").click()
    docs_user.get_by_role("link", name="Shares").click()
    admin_user.get_by_role("link", name="colab_meeting .md").click()
    docs_user.get_by_role("link", name="colab_meeting .md").click()

    # Write the first message and assert it's visible for the other user
    log_note("Sending first validation message")
    first_message = "FIRST_VALIDATION_MESSAGE"
    admin_user.get_by_role("dialog", name="colab_meeting.md").get_by_role("document").locator("div").first.type(first_message)
    expect(docs_user.get_by_text(first_message)).to_be_visible()

    for x in range(1, 7):
        random_message = get_random_text()
        # Admin sends on even, docs_dude on odd
        if x % 2 == 0:
            log_note("Admin adding text")
            admin_user.get_by_role("dialog", name="colab_meeting.md").get_by_role("document").locator("div").first.type(random_message)
            expect(docs_user.get_by_text(random_message)).to_be_visible()
        else:
            log_note("User adding text")
            docs_user.get_by_role("dialog", name="colab_meeting.md").get_by_role("document").locator("div").first.type(random_message)
            expect(admin_user.get_by_text(random_message)).to_be_visible()

        log_note("Sleeping for 10 seconds")
        sleep(10)

    log_note("Closing browsers")
    # ---------------------
    admin_user.close()
    docs_user.close()
    context.close()
    context_two.close()
    browser.close()
    browser_two.close()

def login(page, username, password):
    page.goto("http://nc/login")
    page.get_by_label("Account name or email").click()
    page.get_by_label("Account name or email").fill(username)
    page.get_by_label("Account name or email").press("Tab")
    page.get_by_label("Password", exact=True).fill(password)
    page.get_by_label("Password", exact=True).press("Enter")


with sync_playwright() as playwright:
    collaborate(playwright)
