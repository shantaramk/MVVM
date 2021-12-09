//
//  MovieViewController.swift
//  MVVMDemo
//
//  Created by Shantaram K on 20/03/19.
//  Copyright © 2019 Shantaram K. All rights reserved.
//  test

import UIKit

class MovieViewController: UIViewController {
    
    
    
    //MARK: Internal Properties
    
    let tableView = UITableView(frame: .zero, style: .plain)
    var stackView: UIStackView {
        let stackView = UIStackView(frame: .zero)
        stackView.axis = .vertical
        return stackView
    }
    
    var filterButton: UIButton {
        let button = UIButton(frame: .zero)
        button.setTitle("Filter By Name", for: .normal)
        button.backgroundColor = .systemPink
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(filterButtonTapped(_:)), for: .touchUpInside)
        return button
    }
    
    let viewModel = MovieViewModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Movies"
        self.navigationController?.hidesBarsOnSwipe = true

        // Do any additional setup after loading the view.
        prepareUI()
//        setData()
        fetchMovieList()
    }
    
//    func setData() {
//        self.navigationItem.title = "Movies"
//    }
    
}

//MARK: Prepare UI

extension MovieViewController {
    
    func prepareUI() {
        prepareButton()
        prepareTableView()
        prepareStackView()
        prepareViewModelObserver()
    }
    
    func prepareStackView() {
        let stackView = UIStackView(arrangedSubviews: [tableView, filterButton])
        stackView.axis = .vertical
        stackView.distribution = .fill
        stackView.alignment = .fill
        stackView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(stackView)
        stackView.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 0.0).isActive = true
        stackView.leftAnchor.constraint(equalTo: self.view.leftAnchor, constant: 0.0).isActive = true
        stackView.rightAnchor.constraint(equalTo: self.view.rightAnchor, constant: 0.0).isActive = true
        stackView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: 0.0).isActive = true
    }
    
    func prepareTableView() {
        let newBlue = UIColor(rgb: 151954)
        self.view.backgroundColor = newBlue
        self.tableView.separatorStyle   = UITableViewCell.SeparatorStyle.singleLine
        self.tableView.delegate = self
        self.tableView.dataSource = self
         self.tableView.register(UINib(nibName: "MovieViewCell", bundle: nil), forCellReuseIdentifier: "MovieViewCell")

    }
    
    func prepareButton() {
       self.view.addSubview(filterButton)
       // self.filterButton.heightAnchor.constraint(equalToConstant: 45.0).isActive = true
    }
}

//MARK: Action

extension MovieViewController {
    
    @objc func filterButtonTapped(_ button: UIButton) {
         viewModel.movies = viewModel.movies?.sortByName()
    }
}
//MARK: Private Methods

extension MovieViewController {
    
    func fetchMovieList() {
        viewModel.fetchMovieList()
    }
    
    func prepareViewModelObserver() {
        self.viewModel.movieDidChanges = { (finished, error) in
            if !error {
                self.reloadTableView()
            }
        }
    }
    
    func reloadTableView() {
        self.tableView.reloadData()
    }
}

// MARK: - UITableView Delegate And Datasource Methods

extension MovieViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.movies!.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let cell: MovieViewCell = tableView.dequeueReusableCell(withIdentifier: "MovieViewCell", for: indexPath as IndexPath) as? MovieViewCell else {
            fatalError("AddressCell cell is not found")
        }
        
        let movie = viewModel.movies![indexPath.row]
       cell.movieItem = movie
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        tableView.estimatedRowHeight = 160
        tableView.rowHeight = UITableView.automaticDimension
        return UITableView.automaticDimension
    
    }
}
