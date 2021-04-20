<?php
if (getenv('SMTP_HOST')) {
  $CONFIG = array (
    'mail_smtpmode' => 'smtp',
    'mail_smtphost' => getenv('SMTP_HOST'),
    'mail_smtpport' => getenv('SMTP_PORT') ?: (getenv('SMTP_SECURE') ? 465 : 25),
    'mail_smtpsecure' => getenv('SMTP_SECURE') ?: '',
    'mail_smtpauth' => getenv('SMTP_NAME') && getenv('SMTP_PASSWORD'),
    'mail_smtpauthtype' => getenv('SMTP_AUTHTYPE') ?: 'LOGIN',
    'mail_smtpname' => getenv('SMTP_NAME') ?: '',
    'mail_smtppassword' => getenv('SMTP_PASSWORD') ?: '',
  );
  if (getenv('MAIL_FROM_ADDRESS')) {
    $CONFIG['mail_from_address'] = getenv('MAIL_FROM_ADDRESS');
  }
  if (getenv('MAIL_DOMAIN')) {
    $CONFIG['mail_domain'] = getenv('MAIL_DOMAIN');
  }
}
