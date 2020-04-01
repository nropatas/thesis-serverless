exports.empty = (event, context, callback) => {
  callback(null, { statusCode: 200, body: '' });
};
