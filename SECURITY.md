# Minitar Security Policy

Minitar aims to be secure by default for the data _inside_ of a tar file.

## Supported Versions

Security reports are accepted only for the most recent major release. As of
December 2024, that is the 1.0 release series. Older releases are no longer
supported.

## Reporting a Vulnerability

By preference, use the [Tidelift security contact][tidelift]. Tidelift will
coordinate the fix and disclosure.

Alternatively, Send an email to [minitar@halostatue.ca][email] with the text
`Minitar` in the subject. Emails sent to this address should be encrypted using
[age][age] with the following public key:

```
age1fc6ngxmn02m62fej5cl30lrvwmxn4k3q2atqu53aatekmnqfwumqj4g93w
```

## Exclusions

There are several classes of potential security issues that will not be accepted
for Minitar There are several classes of "security" issues which will not be
accepted for Minitar, because any issues arising from these are a matter of the
library being used incorrectly.

- [CWE-073](https://cwe.mitre.org/data/definitions/73.html)
- [CWE-078](https://cwe.mitre.org/data/definitions/78.html)
- [CWE-088](https://cwe.mitre.org/data/definitions/88.html)

Minitar does _not_ perform validation or sanitization of path names provided to
the convenience classes `Minitar::Output` and `Minitar::Input`, which use
`Kernel.open` for their underlying implementations when not given an IO-like
object.

Improper use of these convenience classes with arbitrary input filenames may
leave your your software to the same class of vulnerability as reported for
Net::FTP ([CVE-2017-17405][CVE-2017-17405]). If the input filename argument
starts with the pipe character (`|`), the command following the pipe character
is executed.

Additionally, the use of the `open-uri` library (which extends `Kernel.open`
with transparent implementations of `Net::HTTP`, `Net::HTTPS`, and `Net::FTP`),
there are other possible vulnerabilities when accepting arbitrary input, as
[detailed][openuri] by Egor Homakov.

These security vulnerabilities may be avoided, even with the `Minitar::Output`
and `Minitar::Input` convenience classes, by providing IO-like objects instead
of pathname-like objects as the source or destination of these classes.

[tidelift]: https://tidelift.com/security
[email]: mailto:minitar@halostatue.ca
[age]: https://github.com/FiloSottile/age
[CVE-2017-17405]: https://nvd.nist.gov/vuln/detail/CVE-2017-17405
[openuri]: https://sakurity.com/blog/2015/02/28/openuri.html
