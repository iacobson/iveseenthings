// Enable TUI dynamic features for Liveview
let TUI = {
  mounted() {
    tabsController();
    datetimeController();
    sidenavController();
    modalController();
  },
};

export { TUI };
