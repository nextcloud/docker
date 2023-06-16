from playwright.sync_api import Playwright, sync_playwright, expect

def collaborate(playwright: Playwright) -> None:
    browser = playwright.chromium.launch(headless=True)
    context = browser.new_context()
    admin_user = context.new_page()

    browser_two = playwright.chromium.launch(headless=True)
    context_two = browser_two.new_context()
    docs_user = context_two.new_page()

    # Login and open the file for both users
    login(admin_user, "Crash", "Override")
    login(docs_user, "docs_dude", "docsrule!12")
    docs_user.get_by_role("button", name="Close modal").click(timeout=15_000)
    admin_user.get_by_role("link", name="Files").click()
    docs_user.get_by_role("link", name="Files").click()
    admin_user.get_by_role("link", name="Shares").click()
    docs_user.get_by_role("link", name="Shares").click()
    admin_user.get_by_role("link", name="colab_meeting .md").click()
    docs_user.get_by_role("link", name="colab_meeting .md").click()

    # Write the first message and assert it's visible for the other user
    first_message = "FIRST_TEST_MESSAGE"
    admin_user.get_by_role("dialog", name="colab_meeting.md").get_by_role("document").locator("div").first.type(first_message)
    expect(docs_user.get_by_text(first_message)).to_be_visible()

    second_message = " some other text"
    docs_user.get_by_role("dialog", name="colab_meeting.md").get_by_role("document").locator("div").first.type(second_message)
    expect(admin_user.get_by_text(second_message)).to_be_visible()

    # ---------------------
    admin_user.close()
    docs_user.close()
    context.close()
    context_two.close()
    browser.close()
    browser_two.close()

def login(page, username, password):
    page.goto("http://nc/login")
    page.get_by_label("Account name or email").click()
    page.get_by_label("Account name or email").fill(username)
    page.get_by_label("Account name or email").press("Tab")
    page.get_by_label("Password", exact=True).fill(password)
    page.get_by_label("Password", exact=True).press("Enter")


with sync_playwright() as playwright:
    collaborate(playwright)
