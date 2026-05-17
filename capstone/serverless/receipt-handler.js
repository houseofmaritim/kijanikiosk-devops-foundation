module.exports.handler = async (event) => {
  console.log("Receipt event received:", JSON.stringify(event, null, 2));

  return {
    statusCode: 200,
    body: JSON.stringify({
      message: "Receipt processed successfully"
    })
  };
};
