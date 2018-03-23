<?php
if (getenv('MAIL_SMTPMODE') == 'smtp') {
  $CONFIG = array (
    'mail_smtpmode' => getenv('MAIL_SMTPMODE'),
    'mail_smtphost' => getenv('MAIL_SMTPHOST'),
    'mail_smtpport' => getenv('MAIL_SMTPPORT'),
    'mail_smtpsecure' => getenv('MAIL_SMTPSECURE'),
    'mail_smtpauth' => getenv('MAIL_SMTPAUTH'),
    'mail_smtpauthtype' => getenv('MAIL_SMTPAUTHTYPE'),
    'mail_smtpname' => getenv('MAIL_SMTPNAME'),
    'mail_smtppassword' => getenv('MAIL_SMTPPASSWORD'),
    'mail_from_address' => getenv('MAIL_FROM_ADDRESS'),
    'mail_domain' => getenv('MAIL_DOMAIN'),
  );
}