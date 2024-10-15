import contextlib
import string
import sys
from time import sleep

from playwright.sync_api import Playwright, sync_playwright, expect

from helpers.helper_functions import log_note, get_random_text, login_nextcloud, close_modal, timeout_handler


def collaborate(playwright: Playwright, browser_name: str) -> None:
    log_note(f"Launch two {browser_name} browsers")
    if browser_name == "firefox":
        browser = playwright.firefox.launch(headless=True)
    else:
        # this leverages new headless mode by Chromium: https://developer.chrome.com/articles/new-headless/
        # The mode is however ~40% slower: https://github.com/microsoft/playwright/issues/21216
        browser = playwright.chromium.launch(headless=False,args=["--headless=new"])
    context = browser.new_context()
    admin_user_page = context.new_page()


    if browser_name == "firefox":
        browser_two = playwright.firefox.launch(headless=True)
    else:
        # this leverages new headless mode by Chromium: https://developer.chrome.com/articles/new-headless/
        # The mode is however ~40% slower: https://github.com/microsoft/playwright/issues/21216
        browser_two = playwright.chromium.launch(headless=False,args=["--headless=new"])
    context_two = browser_two.new_context()
    docs_user_page = context_two.new_page()

    try:
        # Login and open the file for both users
        log_note("Logging in with users")
        login_nextcloud(admin_user_page, "Crash", "Override")
        login_nextcloud(docs_user_page, "docs_dude", "docsrule!12")
        log_note("Opening document with both users")
        close_modal(docs_user_page)

        admin_user_page.get_by_role("link", name="Files", exact=True).click()
        docs_user_page.get_by_role("link", name="Files", exact=True).click()
        admin_user_page.get_by_role("link", name="Shares", exact=True).click()
        docs_user_page.get_by_role("link", name="Shares", exact=True).click()
        admin_user_page.get_by_role("link", name="colab_meeting .md").click()
        docs_user_page.get_by_role("link", name="colab_meeting .md").click()

        # Write the first message and assert it's visible for the other user
        log_note("Sending first validation message")
        first_message = "FIRST_VALIDATION_MESSAGE"
        admin_user_page.get_by_role("dialog", name="colab_meeting.md").get_by_role("document").locator("div").first.type(first_message)
        expect(docs_user_page.get_by_text(first_message)).to_be_visible()
        log_note("GMT_SCI_R=1")

        for x in range(1, 7):
            random_message = get_random_text()
            # Admin sends on even, docs_dude on odd
            if x % 2 == 0:
                log_note("Admin adding text")
                admin_user_page.get_by_role("dialog", name="colab_meeting.md").get_by_role("document").locator("div").first.type(random_message)
                expect(docs_user_page.get_by_text(random_message)).to_be_visible(timeout=15_000)
            else:
                log_note("User adding text")
                docs_user_page.get_by_role("dialog", name="colab_meeting.md").get_by_role("document").locator("div").first.type(random_message)
                expect(admin_user_page.get_by_text(random_message)).to_be_visible(timeout=15_000)

            log_note("GMT_SCI_R=1")
            log_note("Sleeping for 5 seconds")
            sleep(5)

        log_note("Closing browsers")
        # ---------------------
        admin_user_page.close()
        docs_user_page.close()
        context.close()
        context_two.close()
        browser.close()
        browser_two.close()

    except Exception as e:
        if hasattr(e, 'message'): # only Playwright error class has this member
            log_note(f"Exception occurred: {e.message}")
        log_note(f"Page content was: {docs_user_page.content()}")
        log_note(f"Page content was: {admin_user_page.content()}")
        raise e



with sync_playwright() as playwright:
    if len(sys.argv) > 1:
        browser_name = sys.argv[1].lower()
        if browser_name not in ["chromium", "firefox"]:
            print("Invalid browser name. Please choose either 'chromium' or 'firefox'.")
            sys.exit(1)
    else:
        browser_name = "chromium"

    collaborate(playwright, browser_name)
