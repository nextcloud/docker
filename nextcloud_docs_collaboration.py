from playwright.sync_api import Playwright, sync_playwright, expect


def run(playwright: Playwright) -> None:
    browser = playwright.chromium.launch(headless=True)
    context = browser.new_context()
    page = context.new_page()
    page.goto("http://nc/login")
    page.get_by_label("Account name or email").click()
    page.get_by_label("Account name or email").fill("docs_dude")
    page.get_by_label("Account name or email").press("Tab")
    page.get_by_label("Password", exact=True).fill("docsrule!12")
    page.get_by_label("Password", exact=True).press("Enter")
    page.get_by_role("button", name="Close modal").click(timeout=15_000)
    page.get_by_role("link", name="Files").click()
    page.get_by_role("link", name="Shares").click()
    page.get_by_role("link", name="colab_meeting .md Shared by Crash Shared by Crash Actions").click()
    page.close()

    # ---------------------
    context.close()
    browser.close()


with sync_playwright() as playwright:
    run(playwright)
