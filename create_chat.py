from playwright.sync_api import Playwright, sync_playwright, expect


def run(playwright: Playwright) -> None:
    browser = playwright.chromium.launch(headless=False)
    context = browser.new_context()
    page = context.new_page()
    page.goto("http://localhost:8080/login")
    page.get_by_label("Account name or email").click()
    page.get_by_label("Account name or email").fill("Crash")
    page.get_by_label("Account name or email").press("Tab")
    page.get_by_label("Password", exact=True).fill("Override")
    page.get_by_role("button", name="Log in").click()
    page.get_by_role("link", name="Talk", exact=True).click()
    page.get_by_placeholder("Search conversations or users").click()
    page.locator("#app-content-vue").click()
    page.get_by_role("button", name="Create a new group conversation").click()
    page.locator("label").filter(has_text="Allow guests to join via link").locator("path").click()
    page.get_by_placeholder("Conversation name").click()
    page.get_by_placeholder("Conversation name").fill("Drum talk")
    page.get_by_role("button", name="Create conversation").click()
    page.get_by_role("button", name="Copy conversation link").click()
    page.locator("#modal-description-ytlxf").get_by_role("button", name="Close", exact=True).click()
    page.get_by_role("button", name="Reply").click()
    page.get_by_role("textbox", name="Write message, @ to mention someone …").fill("Pretty good! Working on a new drum fill!")
    page.get_by_role("textbox", name="Write message, @ to mention someone …").press("Enter")
    page.close()

    # ---------------------
    context.close()
    browser.close()


with sync_playwright() as playwright:
    run(playwright)
