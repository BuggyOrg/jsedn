import * as chai from 'chai'
import chaiAsPromised from 'chai-as-promised'
import * as jsedn from '../index.js'

chai.use(chaiAsPromised)
const expect = chai.expect


describe('jsedn', () => {
  it('simple newline inside ()', () => {
      var code = `(hallo\ntest\nthere)`
      var out = jsedn.parse(code)
      console.error(out)
      
      expect(out.posLineStart).to.equal(1)
      expect(out.posLineEnd).to.equal(3)
      
      expect(out.val[0].posLineEnd).to.equal(2) // 1 if space bevore \n
      expect(out.val[1].posLineEnd).to.equal(3) // 2 if space bevore \n
      expect(out.val[2].posLineEnd).to.equal(3)
      expect(out.posLineEnd).to.equal(3)
  })
})
