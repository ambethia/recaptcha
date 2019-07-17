To run the v2 examples, start the server with `rails s`. Then go to <http://localhost:3000/captchas>.

To run the v3 examples, you will need a v3 key, which you can get from
https://www.google.com/recaptcha/admin. Unlike v2, where they provide a standard [key you can use for
testing](https://developers.google.com/recaptcha/docs/faq#id-like-to-run-automated-tests-with-recaptcha-what-should-i-do)
(and which is in the [.env](.env) file, no such standard testing key exists for v3, so you need to
obtain your own.

Then set these environment variables:

  export RECAPTCHA_SITE_KEY=your_v3_key
  export RECAPTCHA_SECRET_KEY=your_v3_key

and start the server with `rails s`. Then go to <http://localhost:3000/v3_captchas>.

To run the example of v3 with v2 fallback, you can set:

```
  unset RECAPTCHA_SITE_KEY
  unset RECAPTCHA_SECRET_KEY
  export RECAPTCHA_SITE_KEY_V3=your_v3_key
  export RECAPTCHA_SECRET_KEY_V3=your_v3_key
```

and start the server again with `rails s`. Then go to <http://localhost:3000/v3_captchas?with_v2_fallback=1>.
