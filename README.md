# reCAPTCHA

Author:    Jason L Perry (http://ambethia.com)<br/>
Copyright: Copyright (c) 2007-2013 Jason L Perry<br/>
License:   [MIT](http://creativecommons.org/licenses/MIT/)<br/>
Info:      https://github.com/ambethia/recaptcha<br/>
Bugs:      https://github.com/ambethia/recaptcha/issues<br/>

This plugin adds helpers for the [reCAPTCHA API](https://www.google.com/recaptcha). In your
views you can use the `recaptcha_tags` method to embed the needed javascript,
and you can validate in your controllers with `verify_recaptcha` or `verify_recaptcha!`,
which throws an error on failiure.

## Rails Installation

[obtain a reCAPTCHA API key](https://www.google.com/recaptcha/admin). Note: Use localhost or 127.0.0.1 in domain if using localhost:3000.

```Ruby
gem "recaptcha"
```

Keep keys out of the code base with environment variables.<br/>
Set in production and locally use [dotenv](https://github.com/bkeepers/dotenv), make sure to add it above recaptcha.

Otherwise see [Alternative API key setup](#alternative-api-key-setup).

```
export RECAPTCHA_SITE_KEY  = '6Lc6BAAAAAAAAChqRbQZcn_yyyyyyyyyyyyyyyyy'
export RECAPTCHA_SECRET_KEY = '6Lc6BAAAAAAAAKN3DRm6VA_xxxxxxxxxxxxxxxxx'
```

Add `recaptcha_tags` to the forms you want to protect.

```Erb
<%= form_for @foo do |f| %>
  # ... other tags
  <%= recaptcha_tags %>
  # ... other tags
<% end %>
```

And, add `verify_recaptcha` logic to each form action that you've protected.

```Ruby
# app/controllers/users_controller.rb
@user = User.new(params[:user].permit(:name))
if verify_recaptcha(model: @user) && @user.save
  redirect_to @user
else
  render 'new'
end
```

## Sinatra / Rack / Ruby installation

See [sinatra demo](/demo/sinatra) for details.

 - add `gem 'recaptcha'` to `Gemfile`
 - set env variables
 - `include Recaptcha::ClientHelper` where you need `recaptcha_tags`
 - `include Recaptcha::Verify` where you need `verify_recaptcha`

## recaptcha_tags

Some of the options available:

| Option            | Description |
|-------------------|-------------|
| :noscript         | Include <noscript> content (default `true`)|
| :theme            | Specify the theme to be used per the API. Available options: `dark` and `light`. (default `light`)|
| :ajax             | Render the dynamic AJAX captcha per the API. (default `false`)|
| :site_key         | Override site API key |
| :error            | Override the error code returned from the reCAPTCHA API (default `nil`)|
| :size             | Specify a size (default `nil`)|
| :hl               | Optional. Forces the widget to render in a specific language. Auto-detects the user's language if unspecified. (See [language codes](https://developers.google.com/recaptcha/docs/language)) |
| :nonce            | Optional. Sets nonce attribute for script. Can be generated via `SecureRandom.base64(32)`. (default `nil`)|
| :id               | Specify an html id attribute (default `nil`)|
| :script           | If you do not need to add a script tag by helper you can set the option to false. It's necessary when you add a script tag manualy (default `true`)|
| :callback         | Optional. Name of success callback function, executed when the user submits a successful response |
| :expired_callback | Optional. Name of expiration callback function, executed when the reCAPTCHA response expires and the user needs to re-verify. |
| :error_callback   | Optional. Name of error callback function, executed when reCAPTCHA encounters an error (e.g. network connectivity) |

You can also override the html attributes for the sizes of the generated `textarea` and `iframe`
elements, if CSS isn't your thing. Inspect the source of `recaptcha_tags` to see these options.

## verify_recaptcha

This method returns `true` or `false` after processing the parameters from the reCAPTCHA widget. Why
isn't this a model validation? Because that violates MVC. You can use it like this, or how ever you
like. Passing in the ActiveRecord object is optional, if you do--and the captcha fails to verify--an
error will be added to the object for you to use.

Some of the options available:

| Option       | Description |
|--------------|-------------|
| :model       | Model to set errors.
| :attribute   | Model attribute to receive errors. (default :base)
| :message     | Custom error message.
| :secret_key  | Override secret API key.
| :timeout     | The number of seconds to wait for reCAPTCHA servers before give up. (default `3`)
| :response    | Custom response parameter. (default: params['g-recaptcha-response'])
| :hostname    | Expected hostname or a callable that validates the hostname, see [domain validation](https://developers.google.com/recaptcha/docs/domain_validation) and [hostname](https://developers.google.com/recaptcha/docs/verify#api-response) docs. (default: `nil`, but can be changed by setting `config.hostname`)
| :env         | Current environment. The request to verify will be skipped if the environment is specified in configuration under `skip_verify_env`

## invisible_recaptcha_tags

Make sure to read [Invisible reCAPTCHA](https://developers.google.com/recaptcha/docs/invisible).

### With a single form on a page

1. The `invisible_recaptcha_tags` generates a submit button for you.

```Erb
<%= form_for @foo do |f| %>
  # ... other tags
  <%= invisible_recaptcha_tags text: 'Submit form' %>
<% end %>
```

Then, add `verify_recaptcha` to your controller as seen [above](#rails-installation).

### With multiple forms on a page

1. You will need a custom callback function, which is called after verification with Google's reCAPTCHA service. This callback function must submit the form. Optionally, `invisible_recaptcha_tags` currently implements a JS function called `invisibleRecaptchaSubmit` that is called when no `callback` is passed. Should you wish to override `invisibleRecaptchaSubmit`, you will need to use `invisible_recaptcha_tags script: false`, see lib/recaptcha/client_helper.rb for details.
2. The `invisible_recaptcha_tags` generates a submit button for you.

```Erb
<%= form_for @foo, html: {id: 'invisible-recaptcha-form'} do |f| %>
  # ... other tags
  <%= invisible_recaptcha_tags callback: 'submitInvisibleRecaptchaForm', text: 'Submit form' %>
<% end %>
```

```Javascript
// app/assets/javascripts/application.js
var submitInvisibleRecaptchaForm = function () {
  document.getElementById("invisible-recaptcha-form").submit();
};
```

Finally, add `verify_recaptcha` to your controller as seen [above](#rails-installation).

### Programmatically invoke

1. Specify `ui` option

```Erb
<%= form_for @foo, html: {id: 'invisible-recaptcha-form'} do |f| %>
  # ... other tags
  <button type="button" id="submit-btn">
    Submit
  </button>
  <%= invisible_recaptcha_tags ui: :invisible, callback: 'submitInvisibleRecaptchaForm' %>
<% end %>
```

```Javascript
// app/assets/javascripts/application.js
document.getElementById('submit-btn').addEventListener('click', function (e) {
  // do some validation
  if(isValid) {
    // call reCAPTCHA check
    grecaptcha.execute();
  }
});

var submitInvisibleRecaptchaForm = function () {
  document.getElementById("invisible-recaptcha-form").submit();
};
```

## I18n support
reCAPTCHA passes two types of error explanation to a linked model. It will use the I18n gem
to translate the default error message if I18n is available. To customize the messages to your locale,
add these keys to your I18n backend:

`recaptcha.errors.verification_failed` error message displayed if the captcha words didn't match
`recaptcha.errors.recaptcha_unreachable` displayed if a timeout error occured while attempting to verify the captcha

Also you can translate API response errors to human friendly by adding translations to the locale (`config/locales/en.yml`):

```Yaml
en:
  recaptcha:
    errors:
      verification_failed: 'Fail'
```

## Testing

By default, reCAPTCHA is skipped in "test" and "cucumber" env. To enable it during test:

```Ruby
Recaptcha.configuration.skip_verify_env.delete("test")
```

## Alternative API key setup

### Recaptcha.configure

```Ruby
# config/initializers/recaptcha.rb
Recaptcha.configure do |config|
  config.site_key  = '6Lc6BAAAAAAAAChqRbQZcn_yyyyyyyyyyyyyyyyy'
  config.secret_key = '6Lc6BAAAAAAAAKN3DRm6VA_xxxxxxxxxxxxxxxxx'
  # Uncomment the following line if you are using a proxy server:
  # config.proxy = 'http://myproxy.com.au:8080'
end
```

### Recaptcha.with_configuration

For temporary overwrites (not thread safe).

```Ruby
Recaptcha.with_configuration(site_key: '12345') do
  # Do stuff with the overwritten site_key.
end
```

### Per call

Pass in keys as options at runtime, for code base with multiple reCAPTCHA setups:

```Ruby
recaptcha_tags site_key: '6Lc6BAAAAAAAAChqRbQZcn_yyyyyyyyyyyyyyyyy'

# and

verify_recaptcha secret_key: '6Lc6BAAAAAAAAKN3DRm6VA_xxxxxxxxxxxxxxxxx'
```

## Misc
 - Check out the [wiki](https://github.com/ambethia/recaptcha/wiki) and leave whatever you found valuable there.
 - [Add multiple widgets to the same page](https://github.com/ambethia/recaptcha/wiki/Add-multiple-widgets-to-the-same-page)
 - [Use Recaptcha with Devise](https://github.com/plataformatec/devise/wiki/How-To:-Use-Recaptcha-with-Devise)
