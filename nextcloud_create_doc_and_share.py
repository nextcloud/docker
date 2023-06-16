from playwright.sync_api import Playwright, sync_playwright


def run(playwright: Playwright) -> None:
    browser = playwright.chromium.launch(headless=True)
    context = browser.new_context()
    page = context.new_page()
    page.goto("http://nc/")
    page.get_by_label("Account name or email").click()
    page.get_by_label("Account name or email").fill("Crash")
    page.get_by_label("Account name or email").press("Tab")
    page.get_by_label("Password", exact=True).fill("Override")
    page.get_by_label("Password", exact=True).press("Enter")
    page.get_by_role("link", name="Files").click()
    page.get_by_role("link", name="New file/folder menu").click()
    page.get_by_role("link", name="New text file").click()
    page.locator("#view9-input-file").fill("colab_meeting.md")
    page.locator("#view9-input-file").press("Enter")
    page.get_by_role("button", name="Create a new file with the selected template").click()
    page.get_by_role("button", name="Close modal").click()
    page.get_by_role("link", name="Not favorited colab_meeting .md Share Actions").get_by_role("link", name="Share").click()
    page.get_by_placeholder("Name, email, or Federated Cloud ID …").click()
    page.get_by_placeholder("Name, email, or Federated Cloud ID …").fill("docs")
    page.get_by_text("docs_dude").first.click()
    page.close()

    # ---------------------
    context.close()
    browser.close()


with sync_playwright() as playwright:
    run(playwright)
