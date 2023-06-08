from playwright.sync_api import Playwright, sync_playwright


def run(playwright: Playwright) -> None:
    browser = playwright.chromium.launch(headless=False)
    context = browser.new_context()
    page = context.new_page()
    page.goto("http://localhost:8080/login")
    page.get_by_label("Account name or email").click()
    page.get_by_label("Account name or email").fill("Crash")
    page.get_by_label("Password", exact=True).click()
    page.get_by_label("Password", exact=True).fill("Override")
    page.get_by_role("button", name="Log in").click()
    page.get_by_role("link", name="Open settings menu").click()
    page.get_by_role("link", name="Users").click()
    page.get_by_role("button", name="New user").click()
    page.get_by_placeholder("Username").click()
    page.get_by_placeholder("Username").fill("Splash")
    page.get_by_placeholder("Display name").click()
    page.get_by_placeholder("Display name").fill("Splash")
    page.get_by_placeholder("Password", exact=True).click()
    page.get_by_placeholder("Password", exact=True).fill("cymbals3533")
    page.get_by_role("button", name="Add a new user").click()

    # ---------------------
    context.close()
    browser.close()


with sync_playwright() as playwright:
    run(playwright)
