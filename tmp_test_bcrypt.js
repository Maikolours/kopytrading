const bcrypt = require('bcryptjs');

async function test() {
  const pass = '123456';
  const hash = await bcrypt.hash(pass, 10);
  console.log('Hash:', hash);
  const match = await bcrypt.compare(pass, hash);
  console.log('Match:', match);
}

test();
