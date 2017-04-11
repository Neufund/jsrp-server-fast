BigNum = require 'bignum'
createHash = require 'create-hash'
randomBytes = require 'randombytes'

transform = require './transform'
parameters = require './parameters'

class SRP

	constructor: (length) ->
		@params = parameters.get length

	# x = H(s | H(I | ":" | P))
	# Returns bigInteger
	x: (options) ->
		# Options expects I, P, and salt property, where I is the identifier
		# and P is the password. All of these should be buffers.
		I = options.I
		P = options.P
		salt = options.salt

		identifierPasswordHash = createHash(@params.hash)
			.update(I)
			.update(new Buffer(':'))
			.update(P)
			.digest()

		xHash = createHash(@params.hash)
			.update(salt)
			.update(identifierPasswordHash)
			.digest()

		result = transform.buffer.toBigInteger xHash

		return result

	# v = g^x % N
	# Returns Buffer
	v: (options) ->
		# Expects salt, I, P
		I = options.I
		P = options.P
		salt = options.salt

		result = @params.g.powm @x(options), @params.N
		result = transform.pad.toN result, @params

		return result

	# Returns a random BigInteger
	a: (callback) ->
		randomBytes 32, (err, resultBuf) ->
			result = transform.buffer.toBigInteger resultBuf
			callback err, result

	# Returns a random BigInteger
	b: (callback) ->
		randomBytes 32, (err, resultBuf) ->
			result = transform.buffer.toBigInteger resultBuf
			callback err, result

	# A = g^a % N
	A: (options) ->
		# Expects a, which should be a random BigInteger
		a = options.a

		# Check here to ensure that a.length is not smaller than 256

		result = @params.g.powm a, @params.N
		result = transform.pad.toN result, @params

		return result

	# B = (kv + g^b) % N
	B: (options) ->
		# Expects v, which should be the client verifier BigInteger, and b,
		# which should be a random BigInteger
		v = options.v # BigInteger
		b = options.b # BigInteger

		# This actually ends up being (v + (g^b % N)) % N, this is the way
		# everyone else is doing it, so it's the way we're gonna do it.
		result = @k().mul(v).add(@params.g.powm(b, @params.N)).mod(@params.N)
		result = transform.pad.toN result, @params

		return result

	# u = H(A | B)
	# Returns BigInteger
	u: (options) ->
		# We want A and B, both in buffer format.
		A = options.A # Buffer
		B = options.B # Buffer

		result = createHash(@params.hash)
			.update(A)
			.update(B)
			.digest()

		result = transform.buffer.toBigInteger result

		return result

	# Client S calculation, where S = (B - g^x) ^ (a + u * x) % N
	# Returns Buffer
	clientS: (options) ->
		B = options.B # BigInteger
		a = options.a # BigInteger
		u = options.u # BigInteger
		x = options.x # BigInteger

		result = B
			.sub(
				@k().mul(
					@params.g.powm(x, @params.N)
				)
			)
			.powm(
				a.add(
					u.mul(x)
				),
				@params.N
			)

		result = transform.pad.toN result, @params
		return result

	# S = (A * v^u) ^ b % N
	serverS: (options) ->
		A = options.A # BigInteger
		v = options.v # BigInteger
		u = options.u # BigInteger
		b = options.b # BigInteger

		result = A
			.mul(
				v.powm(u, @params.N)
			)
			.powm(b, @params.N)

		result = transform.pad.toN result, @params
		return result

	# SRP-6 multiplier
	# Returns BigInteger
	k: ->
		result = createHash(@params.hash)
			.update(
				transform.pad.toN(@params.N, @params)
			)
			.update(
				transform.pad.toN(@params.g, @params)
			)
			.digest()

		result = transform.buffer.toBigInteger result
		return result

	K: (options) ->
		S = options.S # Buffer

		result = createHash(@params.hash)
			.update(S)
			.digest()

		return result

	M1: (options) ->
		A = options.A # Buffer
		B = options.B # Buffer
		K = options.K # Buffer

		result = createHash(@params.hash)
			.update(A)
			.update(B)
			.update(K)
			.digest()

		return result

	M2: (options) ->
		A = options.A # Buffer
		M = options.M # Buffer
		K = options.K # Buffer

		result = createHash(@params.hash)
			.update(A)
			.update(M)
			.update(K)
			.digest()

		return result

	generateSalt: (callback) ->
		randomBytes 32, (err, resultBuf) ->
			callback err, resultBuf

	# This is used to ensure that values are not zero when mod N.
	isZeroWhenModN: (thisBigInt) ->
		return thisBigInt.mod(@params.N).eq(BigNum(0))

module.exports = SRP
