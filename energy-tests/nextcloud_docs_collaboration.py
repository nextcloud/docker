import contextlib
import re
import string
import sys
from time import sleep

from playwright.sync_api import Playwright, sync_playwright, expect

from helpers.helper_functions import log_note, get_random_text, login_nextcloud, close_modal, timeout_handler

DOMAIN = 'https://ncs'
#DOMAIN = 'http://localhost:8080'

SLEEP_TIME = 1


def collaborate(playwright: Playwright, browser_name: str, headless=False) -> None:
    log_note(f"Launch two {browser_name} browsers")
    if browser_name == "firefox":
        browser = playwright.firefox.launch(headless=headless, args=['-width', '1280', '-height', '720'])
    else:
        # this leverages new headless mode by Chromium: https://developer.chrome.com/articles/new-headless/
        # The mode is however ~40% slower: https://github.com/microsoft/playwright/issues/21216
        browser = playwright.chromium.launch(headless=headless,args=["--headless=new"])

    context = browser.new_context(ignore_https_errors=True, viewport={'width': 1280, 'height': 720})
    admin_user_page = context.new_page()


    if browser_name == "firefox":
        browser_two = playwright.firefox.launch(headless=headless, args=['-width', '1280', '-height', '720'])
    else:
        # this leverages new headless mode by Chromium: https://developer.chrome.com/articles/new-headless/
        # The mode is however ~40% slower: https://github.com/microsoft/playwright/issues/21216
        browser_two = playwright.chromium.launch(headless=headless,args=["--headless=new"])
    context_two = browser_two.new_context(ignore_https_errors=True, viewport={'width': 1280, 'height': 720})
    docs_user_page = context_two.new_page()

    try:
        # Login and open the file for both users
        log_note("Logging in with users")
        login_nextcloud(admin_user_page, "Crash", "Override", DOMAIN)
        login_nextcloud(docs_user_page, "docs_dude", "docsrule!12", DOMAIN)
        log_note("Opening document with both users")
        close_modal(docs_user_page)

        admin_user_page.get_by_role("link", name="Files").click()
        docs_user_page.get_by_role("link", name="Files").click()

        admin_user_page.get_by_role("link", name="Shares", exact=True).click()
        docs_user_page.get_by_role("link", name="Shares", exact=True).click()

        sort_button = admin_user_page.locator('button.files-list__column-sort-button:has-text("Modified")')
        arrow_icon = sort_button.locator('.menu-up-icon')
        if arrow_icon.count() > 0:
            log_note("The arrow is already pointing up. No need to click the button.")
        else:
            sort_button.click()

        admin_user_page.locator('tr[data-cy-files-list-row][index="0"]').click()

        filename_element = admin_user_page.locator('h2.modal-header__name')
        filename = filename_element.text_content().strip()

        docs_user_page.locator(f'tr[data-cy-files-list-row-name="{filename}"]').click()

        sleep(SLEEP_TIME)
        log_note("Starting to collaborate")

        # Write the first message and assert it's visible for the other user
        log_note("Sending first validation message")
        first_message = "FIRST_VALIDATION_MESSAGE"

        admin_text_box = admin_user_page.locator('div[contenteditable="true"]').first
        user_text_box = docs_user_page.locator('div[contenteditable="true"]').first

        admin_text_box.wait_for(state="visible")
        user_text_box.wait_for(state="visible")

        sleep(SLEEP_TIME)

        admin_user_page.keyboard.type(first_message)

        expect(docs_user_page.get_by_text(first_message)).to_be_visible()

        for x in range(1, 7):
            random_message = get_random_text()
            # Admin sends on even, docs_dude on odd
            if x % 2 == 0:
                log_note("Admin adding text")
                admin_user_page.keyboard.type(random_message) # We could add delay here, but then we need to increase the timeout
                expect(docs_user_page.get_by_text(random_message)).to_be_visible(timeout=15_000)
            else:
                log_note("User adding text")
                docs_user_page.keyboard.type(random_message)
                expect(admin_user_page.get_by_text(random_message)).to_be_visible(timeout=15_000)

            log_note(f"Sleeping for {SLEEP_TIME} seconds")
            sleep(SLEEP_TIME)

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
        #log_note(f"Page content was: {docs_user_page.content()}")
        #log_note(f"Page content was: {admin_user_page.content()}")
        raise e



with sync_playwright() as playwright:
    if len(sys.argv) > 1:
        browser_name = sys.argv[1].lower()
        if browser_name not in ["chromium", "firefox"]:
            print("Invalid browser name. Please choose either 'chromium' or 'firefox'.")
            sys.exit(1)
    else:
        browser_name = "firefox"

    collaborate(playwright, browser_name)
