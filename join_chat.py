from playwright.sync_api import Playwright, sync_playwright, expect


def run(playwright: Playwright) -> None:
    browser = playwright.chromium.launch(headless=False)
    context = browser.new_context()
    page = context.new_page()
    page.goto("http://localhost:8080/call/2sfgz4ir")
    page.get_by_role("button", name="Edit").click()
    page.get_by_placeholder("Guest").fill("Splash")
    page.get_by_role("button", name="Save name").click()
    page.get_by_role("textbox", name="Write message, @ to mention someone …").click()
    page.get_by_role("textbox", name="Write message, @ to mention someone …").fill("Hey, how's it going?")
    page.get_by_role("textbox", name="Write message, @ to mention someone …").press("Enter")
    page.close()

    # ---------------------
    context.close()
    browser.close()


with sync_playwright() as playwright:
    run(playwright)
