import contextlib
import random
import string
import sys
from time import time_ns, sleep

from playwright.sync_api import Playwright, sync_playwright, expect, Error


def get_random_text() -> str:
    size_in_bytes = 1024
    characters = string.ascii_letters + string.digits
    return ''.join(random.choice(characters) for _ in range(size_in_bytes))

def log_note(message: str) -> None:
    timestamp = str(time_ns())[:16]
    print(f"{timestamp} {message}")

def collaborate(playwright: Playwright, browser_name: str) -> None:
    log_note(f"Launch two {browser_name} browsers")
    if browser_name == "firefox":
        browser_type = playwright.firefox
    else:
        browser_type = playwright.chromium

    browser = browser_type.launch(headless=True)
    context = browser.new_context()
    admin_user = context.new_page()

    browser_two = browser_type.launch(headless=True)
    context_two = browser_two.new_context()
    docs_user = context_two.new_page()

    try:
        # Login and open the file for both users
        log_note("Logging in with users")
        login(admin_user, "Crash", "Override")
        login(docs_user, "docs_dude", "docsrule!12")
        log_note("Opening document with both users")
        with contextlib.suppress(Exception):
            sleep(5)
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

    except Error as e:
        log_note(f"Exception occurred: {e.message}")
        log_note(f"Page content was: {docs_user.content()}")
        log_note(f"Page content was: {admin_user.content()}")
        raise e

def login(page, username, password):
    page.goto("http://nc/login")
    page.get_by_label("Account name or email").click()
    page.get_by_label("Account name or email").fill(username)
    page.get_by_label("Account name or email").press("Tab")
    page.get_by_label("Password", exact=True).fill(password)
    page.get_by_label("Password", exact=True).press("Enter")


with sync_playwright() as playwright:
    if len(sys.argv) > 1:
        browser_name = sys.argv[1].lower()
        if browser_name not in ["chromium", "firefox"]:
            print("Invalid browser name. Please choose either 'chromium' or 'firefox'.")
            sys.exit(1)
    else:
        browser_name = "chromium"

    collaborate(playwright, browser_name)
