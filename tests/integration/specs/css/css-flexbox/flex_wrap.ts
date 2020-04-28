describe('flexbox flex-wrap', () => {
  it('should work with wrap', async () => {
    const container1 = document.createElement('div');
    setElementStyle(container1, {
      display: 'flex',
      flexDirection: 'row',
      flexWrap: 'wrap',
      justifyContent: 'center',
      width: '300rpx',
      height: '1000rpx',
      marginBottom: '10rpx',
      backgroundColor: '#ddd',
    });

    document.body.appendChild(container1);

    const child1 = document.createElement('div');
    setElementStyle(child1, {
      display: 'inline-block',
      backgroundColor: '#f40',
      width: '100rpx',
      height: '100rpx',
      margin: '10rpx',
    });
    container1.appendChild(child1);

    const child2 = document.createElement('div');
    setElementStyle(child2, {
      display: 'inline-block',
      backgroundColor: '#f40',
      width: '100rpx',
      height: '100rpx',
      margin: '10rpx',
    });
    container1.appendChild(child2);

    const child3 = document.createElement('div');
    setElementStyle(child3, {
      display: 'inline-block',
      backgroundColor: '#f40',
      width: '100rpx',
      height: '100rpx',
      margin: '10rpx',
    });
    container1.appendChild(child3);
    await matchScreenshot();
  });
});
