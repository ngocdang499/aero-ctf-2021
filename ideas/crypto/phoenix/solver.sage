#!/usr/bin/env sage

from sage.coding.information_set_decoder import LeeBrickellISDAlgorithm


p = 2
F = GF(p)
P.<x> = PolynomialRing(F)


class Cipher:
    def __init__(self, size, params):
        self.size = size
        self.params = params

    def sequence(self, key):
        while True:
            key = key * self.params[0]
            yield key + self.params[1]

    def encrypt(self, key, data, strength, linear=False):
        for value, pbit in zip(self.sequence(key), data):
            xbit = sum(value[i] for i in range(0, strength, 2))
            ybit = mul(value[i] for i in range(1, strength, 2))
            
            if linear:
                yield int(pbit) ^^ int(xbit)
            else:
                yield int(pbit) ^^ int(xbit) ^^ int(ybit)


def ISD_attack(size, stream, params, strength, error):
    M = []
    clean = [0] * len(stream)
    cipher = Cipher(size, params)

    for i in range(size):
        row = list(cipher.encrypt(x^(size - 1 - i), clean, strength, linear=True))
        M.append(row)

    G = matrix(F, M)
    v = vector(F, stream)
    
    C = codes.LinearCode(G)
    A = LeeBrickellISDAlgorithm(C, error)
    A.calibrate()
    
    print(A)
    print(A.time_estimate())
    
    r = A.decode(v)
    e = v - r

    print(e.hamming_weight())
    
    key = G.solve_left(r)
    return P(list(key)[::-1])


def main():
    size = 256
    strength = 10
    error = (15, 25)

    q = P.irreducible_element(size, 'minimal_weight')
    R.<z> = P.quo(q)
    
    a = R(x^255 + x^252 + x^246 + x^245 + x^240 + x^239 + x^236 + x^234 + x^233 + x^232 + x^231 + x^229 + x^228 + x^227 + x^224 + x^223 + x^218 + x^217 + x^216 + x^215 + x^210 + x^209 + x^204 + x^202 + x^200 + x^198 + x^197 + x^196 + x^192 + x^188 + x^187 + x^182 + x^181 + x^180 + x^178 + x^177 + x^176 + x^174 + x^173 + x^172 + x^167 + x^166 + x^161 + x^160 + x^157 + x^155 + x^154 + x^151 + x^150 + x^149 + x^148 + x^147 + x^146 + x^144 + x^140 + x^137 + x^135 + x^133 + x^132 + x^130 + x^129 + x^126 + x^122 + x^119 + x^118 + x^115 + x^112 + x^111 + x^109 + x^107 + x^106 + x^105 + x^104 + x^101 + x^100 + x^99 + x^97 + x^96 + x^94 + x^92 + x^87 + x^86 + x^84 + x^83 + x^81 + x^79 + x^75 + x^71 + x^69 + x^68 + x^67 + x^66 + x^65 + x^63 + x^62 + x^61 + x^56 + x^55 + x^53 + x^52 + x^50 + x^46 + x^44 + x^43 + x^41 + x^39 + x^38 + x^37 + x^36 + x^35 + x^34 + x^33 + x^32 + x^30 + x^29 + x^27 + x^24 + x^21 + x^17 + x^16 + x^14 + x^13 + x^12 + x^11 + x^10 + x^9 + x^5 + x^4 + x^3 + x + 1)
    b = R(x^255 + x^254 + x^250 + x^247 + x^243 + x^242 + x^241 + x^238 + x^235 + x^232 + x^229 + x^227 + x^222 + x^221 + x^219 + x^218 + x^217 + x^216 + x^215 + x^211 + x^207 + x^206 + x^204 + x^202 + x^201 + x^197 + x^195 + x^193 + x^192 + x^190 + x^189 + x^188 + x^186 + x^184 + x^181 + x^180 + x^179 + x^178 + x^176 + x^173 + x^172 + x^169 + x^167 + x^165 + x^161 + x^160 + x^158 + x^149 + x^147 + x^146 + x^145 + x^140 + x^138 + x^137 + x^134 + x^133 + x^132 + x^130 + x^129 + x^128 + x^126 + x^125 + x^124 + x^121 + x^120 + x^118 + x^117 + x^114 + x^112 + x^111 + x^110 + x^109 + x^108 + x^107 + x^106 + x^105 + x^101 + x^96 + x^95 + x^94 + x^93 + x^92 + x^90 + x^89 + x^88 + x^86 + x^85 + x^84 + x^83 + x^81 + x^80 + x^79 + x^78 + x^77 + x^76 + x^71 + x^70 + x^69 + x^68 + x^67 + x^64 + x^63 + x^59 + x^56 + x^55 + x^53 + x^50 + x^46 + x^43 + x^42 + x^40 + x^38 + x^37 + x^35 + x^34 + x^33 + x^25 + x^23 + x^22 + x^21 + x^18 + x^16 + x^14 + x^13 + x^12 + x^11 + x^10 + x^8 + x^3 + x^2 + x)
    
    message = 69824286833704501471834043923417254326103912707315595840737453739249974863266259092449058810542265536810346421685955365128856715192808287450464619418781355923155781710833586631897182535937891456025282049302526058466298304955387306232279075295308862156912873485647349272079984781574084434511227361370780842056
    ciphertext = list(map(int, bin(message)[2:]))

    key = ISD_attack(size, ciphertext[:-size], [a, b], strength, error)
    
    cipher = Cipher(size, [a, b])
    plaintext = cipher.encrypt(key, ciphertext, strength)
    result = int(''.join(str(bin) for bin in plaintext), 2)
    
    print(result.to_bytes(1024, 'big').strip(b'\x00'))


if __name__ == '__main__':
    main()
