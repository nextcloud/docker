import random
import string
from time import time_ns

from playwright.sync_api import Playwright, sync_playwright, expect

def log_note(message: str) -> None:
    timestamp = str(time_ns())[:16]
    print(f"{timestamp} {message}")

def get_random_text() -> str:
    size_in_bytes = 20 * 1024
    characters = string.ascii_letters + string.digits
    return ''.join(random.choice(characters) for _ in range(size_in_bytes))

def send_message(sender, message):
    log_note("Sending message")
    sender.get_by_role("textbox", name="Write message, @ to mention someone …").click()
    sender.get_by_role("textbox", name="Write message, @ to mention someone …").fill(message)
    sender.get_by_role("textbox", name="Write message, @ to mention someone …").press("Enter")

def create_conversation(playwright: Playwright) -> str:
    headless = True
    log_note("Launch browser")
    browser = playwright.chromium.launch(headless=headless)
    context = browser.new_context()
    page = context.new_page()
    log_note("Login as admin")
    page.goto("http://nc/")
    page.get_by_label("Account name or email").click()
    page.get_by_label("Account name or email").fill("Crash")
    page.get_by_label("Account name or email").press("Tab")
    page.get_by_label("Password", exact=True).fill("Override")
    page.get_by_role("button", name="Log in").click()

    # Wait for the modal to load. As it seems you can't close it while it is showing the opening animation.
    log_note("Close first-time run popup")
    page.get_by_role("button", name="Close modal").click(timeout=15_000)

    log_note("Open Talk app")
    page.get_by_role("link", name="Talk", exact=True).click()
    page.wait_for_url("**/apps/spreed/")

    # Headless browsers trigger a warning in Nextcloud, however they actually work fine
    if headless:
        log_note("Close headless warning")
        page.wait_for_selector('.toast-close')
        page.click('.toast-close')

        page.wait_for_selector('.toast-close')
        page.click('.toast-close')

    log_note("Create conversation")
    page.get_by_role("button", name="Create a new group conversation").click()
    page.get_by_placeholder("Conversation name").fill("Random talk")
    page.locator("label").filter(has_text="Allow guests to join via link").locator("svg").click()
    page.get_by_role("button", name="Create conversation").click()
    page.get_by_role("button", name="Copy conversation link").click()
    log_note("Close browser")

    # ---------------------
    page.close()
    context.close()
    browser.close()

    return page.url

def talk(playwright: Playwright, url: str) -> None:
    headless = True
    action_delay_ms = 300
    browser_count = 5

    # Launch browsers
    log_note(f"Launching {browser_count} browsers")
    browsers = [playwright.chromium.launch(headless=headless, slow_mo=action_delay_ms) for _ in range(browser_count)]
    contexts = [browser.new_context() for browser in browsers]
    pages = [context.new_page() for context in contexts]

    # Go to URL for all users
    log_note("Navigating to Talk conversation")
    for page in pages:
        page.goto(url)

    # Close toast messages for headless browsers
    if headless:
        log_note("Close headless warning")
        for page in pages:
            page.wait_for_selector('.toast-close').click()

    # Perform actions for all users
    log_note("Set guest usernames")
    for page in pages:
        page.get_by_role("button", name="Edit").click()
        page.get_by_placeholder("Guest").fill(f"Dude#{pages.index(page) + 1}")
        page.get_by_role("button", name="Save name").click()

    # Send first message and check for visibility
    log_note("Send the first validation message")
    sender = pages[0]
    message = "Let's send some random text!"
    send_message(sender, message)
    log_note("Validate the first message got received")
    for page in pages[1:]:
        expect(page.get_by_text(message, exact=True)).to_be_visible()

    # Send random text and validate it was received by other users
    log_note("Start sending random messages")
    for i, sender in enumerate(pages):
        receivers = pages[:i] + pages[i + 1:]
        random_text = get_random_text()

        send_message(sender, random_text)
        for receiver in receivers:
            expect(receiver.get_by_text(random_text, exact=True)).to_be_visible()
        log_note("Message received by all users")

    # --------------------
    # Close all users
    log_note("Close all browsers")
    for page in pages:
        page.close()

    for context in contexts:
        context.close()

    for browser in browsers:
        browser.close()


with sync_playwright() as playwright:
    conversation_link = create_conversation(playwright)
    talk(playwright, conversation_link)
