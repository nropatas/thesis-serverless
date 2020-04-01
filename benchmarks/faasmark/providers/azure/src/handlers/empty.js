module.exports = (context, req) => {
  req.res = { status: 200, body: '' };
  context.done();
};
