import contextlib
import os
import sys
from time import time_ns, sleep
import signal
import random
import string
from multiprocessing import Pool

from playwright.sync_api import Playwright, sync_playwright, expect

from helpers.helper_functions import log_note, get_random_text, login_nextcloud, close_modal, timeout_handler

DOMAIN = 'https://ncs'
#DOMAIN = 'http://localhost:8080'

SLEEP_TIME = 1
CHAT_SESSIONS = 2
CHAT_TIME_SEC = 10

def join(browser_name: str, download_url:str ,headless=False ) -> None:
    with sync_playwright() as playwright:
        log_note(f"Launching join browser {browser_name}")
        if browser_name == "firefox":
            browser = playwright.firefox.launch(headless=headless,
                                                firefox_user_prefs = {
                                                    "media.navigator.streams.fake": True,
                                                    "media.navigator.permission.disabled": True
                                                },
                                                args=['-width', '1280', '-height', '720']
                                            )
        else:
            # this leverages new headless mode by Chromium: https://developer.chrome.com/articles/new-headless/
            # The mode is however ~40% slower: https://github.com/microsoft/playwright/issues/21216
            browser = playwright.chromium.launch(headless=headless,args=["--headless=new"])

        context = browser.new_context(
            ignore_https_errors=True,
            viewport={'width': 1280, 'height': 720}
        )
        page = context.new_page()

        try:

            page.goto(download_url)

            sleep(SLEEP_TIME)

            guest_name = "Guest " + ''.join(random.choices(string.ascii_letters, k=5))
            page.get_by_placeholder('Guest').fill(guest_name)

            page.get_by_role('button', name="Submit name and join").click()

            page.locator('.message-main').get_by_role("button", name="Join call").click()


            page.locator('.media-settings__call-buttons').get_by_role("button", name="Join call").click()

            log_note(f"{guest_name} joined the chat")

            sleep(CHAT_TIME_SEC)

            page.get_by_role("button", name="Leave call").click()

            sleep(SLEEP_TIME)

            page.close()
            log_note("Close download browser")

        except Exception as e:
            if hasattr(e, 'message'): # only Playwright error class has this member
                log_note(f"Exception occurred: {e.message}")

            # set a timeout. Since the call to page.content() is blocking we need to defer it to the OS
            signal.signal(signal.SIGALRM, timeout_handler)
            signal.alarm(20)
            #log_note(f"Page content was: {page.content()}")
            signal.alarm(0) # remove timeout signal

            raise e

        # ---------------------
        context.close()
        browser.close()

def run(playwright: Playwright, browser_name: str, headless=False) -> None:
    log_note(f"Launch browser {browser_name}")
    if browser_name == "firefox":
        browser = playwright.firefox.launch(headless=headless,
                                            firefox_user_prefs = {
                                                "media.navigator.streams.fake": True,
                                                "media.navigator.permission.disabled": True
                                            },
                                            args=['-width', '1280', '-height', '720']
                                        )
    else:
        # this leverages new headless mode by Chromium: https://developer.chrome.com/articles/new-headless/
        # The mode is however ~40% slower: https://github.com/microsoft/playwright/issues/21216
        browser = playwright.chromium.launch(headless=headless,args=["--headless=new"])

    context = browser.new_context(
        ignore_https_errors=True,
        viewport={'width': 1280, 'height': 720}
    )
    page = context.new_page()

    try:
        page.goto(f"{DOMAIN}/login")
        log_note("Login")
        login_nextcloud(page, domain=DOMAIN)

        log_note("Wait for welcome popup")
        #close_modal(page)

        log_note("Go to Talk")
        page.locator('#header a[title=Talk]').click()
        page.wait_for_url("**/apps/spreed/")

        sleep(SLEEP_TIME)

        log_note("Start new chat session")

        page.locator('button.action-item__menutoggle:has(.chat-plus-icon)').click()

        page.locator('button.action-button.button-vue.focusable:has-text("Create a new conversation")').click()

        chat_name = "Chat " + ''.join(random.choices(string.ascii_letters, k=5))
        page.get_by_placeholder('Enter a name for this conversation').fill(chat_name)

        page.locator(f'text="Allow guests to join via link"').click()

        sleep(SLEEP_TIME)

        page.get_by_role("button", name="Create conversation").click()

        page.get_by_role("button", name="Copy conversation link").click()

        sleep(SLEEP_TIME)

        page.locator('.modal-container').locator('.empty-content__action').get_by_role('button', name="Close").click()

        link_url = page.evaluate('navigator.clipboard.readText()')

        log_note(f"Chat url is: {link_url}")

        sleep(SLEEP_TIME)

        page.get_by_role("button", name="Start call").click()

        page.locator('.media-settings__call-buttons').get_by_role("button", name="Start call").click()

        sleep(SLEEP_TIME)

        log_note(f"Starting {CHAT_SESSIONS} Chat clients")

        args = [(browser_name, link_url, headless) for _ in range(CHAT_SESSIONS)]
        with Pool(processes=CHAT_SESSIONS) as pool:
            pool.starmap(join, args)

        page.get_by_role("button", name="Leave call").click()
        page.get_by_role('menuitem', name='Leave call').click()

        sleep(SLEEP_TIME)


        page.close()
        log_note("Close browser")

    except Exception as e:
        if hasattr(e, 'message'): # only Playwright error class has this member
            log_note(f"Exception occurred: {e.message}")

        # set a timeout. Since the call to page.content() is blocking we need to defer it to the OS
        signal.signal(signal.SIGALRM, timeout_handler)
        signal.alarm(20)
        #log_note(f"Page content was: {page.content()}")
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
        browser_name = "firefox"

    with sync_playwright() as playwright:
        run(playwright, browser_name)
