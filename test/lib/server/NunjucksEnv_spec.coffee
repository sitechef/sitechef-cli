Nj = require '../../../lib/server/NunjucksEnv'

describe "NunjucksEnv", ->

  describe "Filters", ->

    describe "rnd", ->

      it "should generate a random number", ->
        a = Nj.filters.rnd(10000)
        expect(a).toBeGreaterThan(0)
        expect(a).toBeLessThan(10000)
        b = Nj.filters.rnd(10000)
        expect(b).not.toBe(a)

      it "should return null if null value entered", ->
        expect(Nj.filters.rnd(null))
          .toBe null

    describe "nl2br", ->
      it "should return input unless string", ->

        a = ['a']

        expect(Nj.filters.nl2br(a)[0])
          .toBe 'a'

      it "should replace multiple line breaks", ->
        expect(
          Nj.filters.nl2br("\n\naaa\n")
        ).toBe("<br><br>aaa<br>")

    describe "json_encode", ->
      it "should convert to json and escape slashes", ->
        expect(
          Nj.filters.json_encode(testObject:'"test/')
        ).toBe("{\"testObject\":\"\\\"test\\/\"}")

      it "should convert null", ->

        expect(Nj.filters.json_encode(null))
          .toBe 'null'

    describe "striptags", ->

      it "should remove all html tags but only from strings", ->
        expect(
          Nj
            .filters
            .striptags("<test></test><script>sets</script>")
        ).toBe('sets')

      it "should return original if not string", ->

        expect(
          Nj.filters.striptags({a:'a'}).a
        ).toBe 'a'

    describe "formatDate", ->

      it "should format a date correctly with default syntax", ->

        expect(
          Nj.filters
            .format_date('2014-12-10 10:25:22', 'ddd Do MMMM, YYYY')
        ).toBe 'Wed 10th December, 2014'


      it "should ignore non strings", ->

        expect(
          Nj.filters.format_date(null)
        ).toBe null

