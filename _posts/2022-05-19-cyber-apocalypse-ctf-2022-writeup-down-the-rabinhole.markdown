---
layout: post
title:  "Cyber Apocalypse CTF 2022 Writeup - Down the Rabinhole"
date:   "2022-05-19"
author: Richard Fan
toc:    true
---

## The challenge

```python
from Crypto.Util.number import getPrime, isPrime, bytes_to_long
from Crypto.Util.Padding import pad
import os


FLAG = b"HTB{--REDACTED--}"


def getPrimes(coefficient):
    while True:
        a = getPrime(512)
        p = 3 * coefficient * a + 2
        if isPrime(p):
            break
    while True:
        b = getPrime(512)
        q = 3 * coefficient * b + 2
        if isPrime(q):
            break
    return p, q


def encrypt(message, coefficient):
    p, q = getPrimes(coefficient)
    n = p * q

    padded_message = bytes_to_long(pad(message, 64))
    message = bytes_to_long(message)

    c1 = (message * (message + coefficient)) % n
    c2 = (padded_message * (padded_message + coefficient)) % n
    return (n, c1, c2)


def main():
    coefficient = getPrime(128)
    out = ""

    message = FLAG[0:len(FLAG)//2]
    n1, c1, c2 = encrypt(message, coefficient)
    out += f"{n1}\n{c1}\n{c2}\n"

    message = FLAG[len(FLAG)//2:]
    n2, c3, c4 = encrypt(message, coefficient)
    out += f"{n2}\n{c3}\n{c4}"

    with open("out.txt", "w") as f:
        f.write(out)


if __name__ == '__main__':
    main()

```

The python script performs encryption on the flag then store in a text file:

```
59695566410375916085091065597867624599396247120105936423853186912270957035981683790353782357813780840261434564512137529316306287245132306537487688075992115491809442873176686026221661043777720872604111654524551850568278941757944240802222861051514726510684250078771979880364039814240006038057748087210740783689350438039317498789505078530402846140787188830971536805605748267334628057592989
206131769237721955001530863959688756686125485413899261197125641745745636359058664398433013356663394210624150086689905532
14350341133918883930676906390648724486852266960811870561648194176794020698141189777337348951219934072588842789694987397861496993878758159916334335632468891342228755755695273096621152247970509517996580512069034691932835017774636881861331636331496873041705094768329156701838193429109420730982051593645140188946
56438641309774959123579452414864548345708278641778632906871133633348990457713200426806112132039095059800662176837023585166134224681069774331148738554157081531312104961252755406614635488382297434171375724135403083446853715913787796744272218693049072693460001363598351151832646947233969595478647666992523249343972394051106514947235445828889363124242280013397047951812688863313932909903047
429546912004731012886527767254149694574730322956287028161761007271362927652041138366004560890773167255588200792979452452
29903904396126887576044949247400308530425862142675118500848365445245957090320752747039056821346410855821626622960719507094119542088455732058232895757115241568569663893434035594991241152575495936972994239671806350060725033375704703416762794475486000391074743029264587481673930383986479738961452214727157980946
```

## Similar challenge

This challenge is similar to **Two Rabin** in Asian Cyber Security Challenge. There is a writeup from amyriad [here](https://hackmd.io/@amyriad/acsc#Two-Rabin-crypto-Score-360-20-Solves){:target="_blank"}

## Solution

###  Franklin–Reiter related-message attack

The flag is split into 2 parts and each part is encrypted with and without padding. So the cipertext pairs (`c1`, `c2`) and (`c3`, `c4`) differs by the padding bytes.

We can apply Franklin–Reiter related-message attack on each cipertext pair by applying amyriad's code

### Guessing the missing parts

Unlike the **Two Rabin** challenge, the flag length and the value of coefficient (or **B** in **Two Rabin** challenge) are unknown to us.

#### Length of the flag
From the challenge code, we can see:
 * The flag is split into half and padded to 64-byte long, so the padding of both should be the same

 * The same coefficient is used for addition in 2 sets of encryption.

 * The length of modulus used in 2 sets of encryption is larger than the message being encrypted

    `n` is (512 + 128) * 2 = 1280-bit long and the message being encrypted is 512 * 2 = 1024-bit long

    So we can simply ignore the modulus

Based on these 3 findings, we can assume `c2` and `c4` will have the the same Least Significant Bytes (LSB). And the length of that LSBs is the same as the plaintext padding.

To better understand why, we can think of multiplication in decimal system

> 12345 * 23456 = 0289564320

> 34345 * 45456 = 1561186320

When we multiply numbers with the same least significant digits (`345` and `456`), the result will have the same length of same least significant digits (`320`) no matter what the other part is.

By comparing the bytestring of `c2` and `c4`, we can see they have 39 same LSBs

```python
c2 = b"\x14o\x81!\x1cg\x9e{)\xde\xa9\xfa\xb7\x99\x89\x8b\x17\xcf}\x008\x10m\xccx.H\x07\xd4D\x8f@\xc0\xbfJrN\x0e\xe3P\xeb\xe4h\xd6\xa2\xc6\xb1\x1fGR\xa6U\x90\xe6m\x83\xb2\xe3\xe6|\xf6\xe1\xa2\x85\x18+\x05\x1e\xfc3\x98\xa3\xe7`\xfa\x01\x03z\xc9:h%\xdd\xed\xc0\xb6\xa7\x94\xe9\xb1\xba\xc3\xcc\xd5\xde\xe7\xf0\xfa\x03\x0c\x15\x1e'09BKT]foxcE\xf0(\xc3 \xac\x9eiS\xe6H\xb5\x17\x9f\x12"
c4 = b"*\x95\xa6\x9a7\x90\xe3$\xe4c{O$j5D\xfcF\x837\xdf\xa4\xa2\x98\xf2\x99\xa7\xe6\x94FB\x97\x90\xf8\xdd\xd4\xcb]k(k\xa2\xdb\x83\xa3\xe4\x9a\xc2NSVN{\x18IS\x10\x88\x11g\xf2k\xb7\x95\xe0C\xdcf7\x15\x88B\xe9\x88Q\x84\x95\x86\x0e\x98E\xad7lu\xf6\xa7u\xd6\xb1\xba\xc3\xcc\xd5\xde\xe7\xf0\xfa\x03\x0c\x15\x1e'09BKT]foxcE\xf0(\xc3 \xac\x9eiS\xe6H\xb5\x17\x9f\x12"
lsb = b"\xb1\xba\xc3\xcc\xd5\xde\xe7\xf0\xfa\x03\x0c\x15\x1e'09BKT]foxcE\xf0(\xc3 \xac\x9eiS\xe6H\xb5\x17\x9f\x12"
```

Because of how **PKCS#7** performs padding, we also know the last 39 bytes of the padded plaintext is 39 of `\x27` (Hex code of decimal number `39`:

```
\x27\x27\x27\x27\x27\x27\x27\x27\x27\x27\x27\x27\x27\x27\x27\x27\x27\x27\x27\x27\x27\x27\x27\x27\x27\x27\x27\x27\x27\x27\x27\x27\x27\x27\x27\x27\x27\x27\x27
```

#### The value of coefficient

We now knows part of the plaintext and its corresponding part of the ciphertext, we can guess the value of coefficient.

The relationship between them is:

```python
ciphertext = padded_msg * (padded_msg + coefficient) % n
```

Because we only know part of the padded_msg, we cannot simply get the coefficient by performing division on ciphertext.

But we also don't brute-force a 128-bit long number one-by-one.

Instead, we can brute-force the coefficient byte-by-byte.

For example, when we want to know `2467 * x = 3584551`, we don't need to brute-force the number from `1` to `99999`.

We can first brute-force the last digit: `2467 * 3 = 7401`, which has the same last digit with the result. And we can assume the last digit of `x` is `3`

Then `2467 * 53 = 130751` , which has the same last 2 digit with the result. And we can assume the last 2 digit of `x` is `53`

Using the same method, we can instantly brute-force the coefficient by the following script:

```python
ct = b'\x9c\xa5\xae\xb7\xc0\xc9\xd2\xdb\xe4\xed\xf7\x00\t\x12\x1b$-6?HQZcX%\xdaa\xbb\x107\x86\x8d\x89\r\x95\xc59_P'

pt = b'\x27\x27\x27\x27\x27\x27\x27\x27\x27\x27\x27\x27\x27\x27\x27\x27\x27\x27\x27\x27\x27\x27\x27\x27\x27\x27\x27\x27\x27\x27\x27\x27\x27\x27\x27\x27\x27\x27\x27'
pt = bytes_to_long(pt)

coefficient = b''
for j in range(16):
    known_part = bytes_to_long(coefficient)
    for k in range(256):
        tmp = long_to_bytes(pt*(pt+k*(256 ** j)+known_part))
        if tmp[-j+1:] == ct[-j+1:]:
            coefficient = long_to_bytes(k) + coefficient
            break

print(bytes_to_long(coefficient))
```

The coefficient is `263063435253385937926984981365320113271`

### Putting all parts together

Based on the length of flag and the value of coefficient, we can alter amyriad's code as follow:
os
```python
n = 56438641309774959123579452414864548345708278641778632906871133633348990457713200426806112132039095059800662176837023585166134224681069774331148738554157081531312104961252755406614635488382297434171375724135403083446853715913787796744272218693049072693460001363598351151832646947233969595478647666992523249343972394051106514947235445828889363124242280013397047951812688863313932909903047
e = 2
B = 263063435253385937926984981365320113271
c1= 429546912004731012886527767254149694574730322956287028161761007271362927652041138366004560890773167255588200792979452452
c2= 29903904396126887576044949247400308530425862142675118500848365445245957090320752747039056821346410855821626622960719507094119542088455732058232895757115241568569663893434035594991241152575495936972994239671806350060725033375704703416762794475486000391074743029264587481673930383986479738961452214727157980946
delta = (B + n) >> 1
c1 = (c1 + delta^2) % n
c2 = (c2 + delta^2) % n
# Source: https://github.com/ashutosh1206/Crypton/blob/master/RSA-encryption/Attack-Franklin-Reiter/exploit.sage
def gcd(a, b):
     while b:
         a, b = b, a % b
     return a.monic()
def franklinreiter(C1, C2, e, N, a, b):
     P.<X> = PolynomialRing(Zmod(N))
     g1 = (a*X + b)^e - C1
     g2 = X^e - C2
     result = -gcd(g1, g2).coefficients()[0]
     return result
def int_to_bytes(x: int) -> bytes:
     return x.to_bytes((x.bit_length() + 7) // 8, 'big')
bg = 0x272727272727272727272727272727272727272727272727272727272727272727272727272727
soln = franklinreiter(c2, c1, e, n, 1 << 312, bg + delta - (delta << 312)) - delta
print(int_to_bytes(int(soln)))
```

Parameters I have changed:

 * The value of `B` is same as the coefficient we found
 * `n`, `c1`, `c2` is the value from the text file
 * Change `bg` to our plaintext padding
 * Change the bit shift value to `312` (39 bytes)

After running the `franklinreiter` with (`n1`, `c1`, `c2`) and (`n2`, `c3`, `c4`) respectively, we can get the flag:

```
HTB{gcd_+_2_*_R@6in_.|5_thi5_@_cro55over_epi5ode?}
```
