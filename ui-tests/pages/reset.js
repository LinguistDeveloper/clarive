var commands = {
    reset: function() {
        this
          .navigate()
          ;

        this.api.pause(1000);

        return this;
    }
};

module.exports = {
    url: function () { return this.api.launchUrl + '/test/setup' },
    commands: [commands],
    elements: { }
};
