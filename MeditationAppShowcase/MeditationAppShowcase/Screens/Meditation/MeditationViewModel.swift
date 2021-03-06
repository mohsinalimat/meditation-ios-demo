protocol MeditationViewModeling: class {
    var navigationTitle: ((String) -> Void)? { get set }
    var latestSongViewModels: (([SongViewModeling]) -> Void)? { get set }
    func didSelect(isSelected: Bool, index: Int)
    func viewDidAppear()
    func viewWillDisappear()
    func backAction()
    var beginHeightUpdate: (() -> Void)? { get set }
    var endHeightUpdate: (() -> Void)? { get set }
    var closeMeditation: (() -> Void)? { get set }
}

class MeditationViewModel: MeditationViewModeling {

    init(viewModels: [SongViewModeling],
         actionOperator: ActionOperating,
         tabBarOperator: TabBarOperating,
         musicPlayer: MusicPlaying,
         screenStateOperator: MeditationScreenStateOperating) {
        self.viewModels = viewModels
        self.actionOperator = actionOperator
        self.tabBarOperator = tabBarOperator
        self.musicPlayer = musicPlayer
        self.screenStateOperator = screenStateOperator
        configure()
    }

    // MARK: - MeditationViewModeling

    var navigationTitle: ((String) -> Void)?

    var latestSongViewModels: (([SongViewModeling]) -> Void)?

    func didSelect(isSelected: Bool, index: Int) {
        beginHeightUpdate?()
        musicPlayer.select(isSelected: isSelected, index: index, viewModels: viewModels)
        endHeightUpdate?()
    }

    func viewDidAppear() {
        latestSongViewModels?(viewModels)
        disposable = actionOperator.actionHandler.addHandler(
            target: self,
            handler: MeditationViewModel.handleAction)
        tabBarOperator.isBarVisible = true
        screenStateOperator.repeatCurrentState()
    }

    func viewWillDisappear() {
        disposable?.dispose()
    }

    func backAction() {
        screenStateOperator.previous()
    }

    var beginHeightUpdate: (() -> Void)?
    var endHeightUpdate: (() -> Void)?

    var closeMeditation: (() -> Void)?

    // MARK: - Privates

    private let viewModels: [SongViewModeling]
    private let actionOperator: ActionOperating
    private let tabBarOperator: TabBarOperating
    private let musicPlayer: MusicPlaying
    private let screenStateOperator: MeditationScreenStateOperating
    private var disposable: Disposable?

    private func handleAction(action: ActionViewController.Action) {
        switch action {
        case .button:
            screenStateOperator.next()
        case .rewind:
            beginHeightUpdate?()
            musicPlayer.playPrevious(viewModels: viewModels)
            endHeightUpdate?()
        case .play: ()
        case .forward:
            beginHeightUpdate?()
            musicPlayer.playNext(viewModels: viewModels)
            endHeightUpdate?()
        }
    }

    private func configure() {
        screenStateOperator.stateUpdated = { [weak self] state in
            guard let `self` = self else { return }
            switch state {
            case .dismiss:
                self.closeMeditation?()
            case .picking:
                self.actionOperator.set(mode: .singleButton(title: "START MEDITATION SESSION"))
                self.beginHeightUpdate?()
                self.musicPlayer.updateToSongPicking(viewModels: self.viewModels)
                self.endHeightUpdate?()
                self.navigationTitle?("Pick meditation song")
            case .listening:
                self.actionOperator.set(mode: .player)
                self.beginHeightUpdate?()
                self.musicPlayer.updateToSongListening(viewModels: self.viewModels)
                self.endHeightUpdate?()
                self.navigationTitle?("Player")
            case .finished:
                self.endHeightUpdate = nil
                self.closeMeditation?()
            }
        }

        musicPlayer.didFinishPlaying = { [weak self] in self?.screenStateOperator.next() }
    }

}
