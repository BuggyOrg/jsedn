import * as chai from 'chai'
import chaiAsPromised from 'chai-as-promised'
import * as jsedn from '../index.js'

chai.use(chaiAsPromised)
const expect = chai.expect


describe('jsedn', () => {
  it('simple newline inside ()', () => {
      var code = `(hallo\ntest\nthere)`
      var out = jsedn.parse(code)
      
      expect(out.posLineStart).to.equal(1)
      expect(out.posLineEnd).to.equal(3)
      
      expect(out.val[0].posLineEnd).to.equal(2) // 1 if space bevore \n
      expect(out.val[1].posLineEnd).to.equal(3) // 2 if space bevore \n
      expect(out.val[2].posLineEnd).to.equal(3)
      expect(out.posLineEnd).to.equal(3)
  })

  it('supports empty tags', () => {
    var out = jsedn.parse('#(foo)').jsEncode()
    expect(out.tag).to.equal('')
    expect(out.value).to.deep.equal(['foo'])
  })

  it('does not treat tuples and lists with empty tags as sets', () => {
    jsedn.parse('#(+ %1 %1)') // should work
    jsedn.parse('#[+ %1 %1]') // should work
    expect(() => jsedn.parse('#{+ %1 %1}')).to.throw('set not distinct')
  })
})
