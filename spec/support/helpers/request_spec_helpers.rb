# frozen_string_literal: true

module RequestSpecHelpers
  # Currently duplicated in test/test_helper until it becomes obvious how to refactor.
  def login(user)
    login_without_redirect(user)
    follow_redirect! while response.redirect? # There may be several redirects.
    assert_response(:success)
    user.reload # Some stuff may have changed in database during login process
  end

  def login_without_redirect(user)
    post("/en/user-session", params: {user_session: {login: user.login, password: test_password}})
  end

  def logout
    delete("/en/user-session")
    follow_redirect!
  end

  # Needed for older request specs, maybe related to assert_select.
  # See http://blog.cynthiakiser.com/blog/page/5/
  def document_root_element
    html_document.root
  end
end
