# Natural Language Understanding API Samples

This directory contains sample code for using Natural Language Understanding API.

OLAMI website and documentation: [http://olami.ai](http://olami.ai)

## Perl modules

Perl module is in your @INC include, You may also need to install some modules by the following steps (example by yum in bash):  

```
yum install -y perl-Time-HiRes

yum install -y perl-CPAN*
perl -MCPAN -e 'install Math::Round'

yum install -y perl-IO-Socket-SSL-*
```

## Run the application (by Python 3):

> 1. Replace **your_perl_bin** to your Perl binary path.
> 2. Replace **api_url, your_app_key, your_app_secret, your_text_input** in accordance to your needs and your own data.

```
your_perl_bin NluApiTest.pl api_url your_app_key your_app_secret your_text_input
```

- For example: (Simplified Chinese Request with the text "我爱欧拉蜜")

```
perl NluApiTest.pl https://cn.olami.ai/cloudservice/api 172c5b7b7121407ba572da444a999999 2115d0888bd049549581b7a0a6888888 我爱欧拉蜜
```

- For example: (Traditional Chinese Request with the text "我愛歐拉蜜")

```
perl NluApiTest.pl https://tw.olami.ai/cloudservice/api 999888777666555444333222111000aa 111222333444555666777888999000aa 我愛歐拉蜜
```
